import torch
import torch.nn as nn
from torch.utils.data import DataLoader
from torchvision import datasets, transforms
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
import json
import argparse
import torchvision.models as models
from sklearn.metrics import f1_score, classification_report

def load_model(model_path, device, num_classes):
    """
    Load the trained model from the specified checkpoint.
    
    Args:
        model_path (str): Path to the .pth.tar model file.
        device (torch.device): Device to load the model on.

    Returns:
        torch.nn.Module: Loaded model.
        dict: Checkpoint containing model state and other metadata.
    """
    checkpoint = torch.load(model_path, map_location=device)
    
    # Retrieve architecture
    arch = checkpoint.get('arch', 'vgg16')
    
    # Initialize model
    if arch.startswith('vgg'):
        model = getattr(models, arch)()
    elif arch.startswith('resnet'):
        model = getattr(models, arch)()
    else:
        raise ValueError(f"Unsupported architecture: {arch}")
    
    # Replace classifier if needed (based on main.py)
    if arch.startswith('vgg'):
        num_features = model.classifier[0].in_features
        model.classifier = nn.Sequential(
            nn.Linear(num_features, 4096),
            nn.ReLU(inplace=True),
            nn.Dropout(),
            nn.Linear(4096, 4096),
            nn.ReLU(inplace=True),
            nn.Dropout(),
            nn.Linear(4096, num_classes),
            nn.Softmax(dim=1)
        )
    
    # Load state_dict
    model.load_state_dict(checkpoint['state_dict'])
    
    model.to(device)
    model.eval()
    return model, checkpoint

def get_data_loaders(test_dir, batch_size=64):
    """
    Prepare the test data loader.
    
    Args:
        test_dir (str): Directory path for the test dataset.
        batch_size (int): Number of samples per batch.

    Returns:
        DataLoader: Test data loader.
    """
    transform = transforms.Compose([
                transforms.Resize(256),
                transforms.CenterCrop(224),
                transforms.ToTensor(),
                transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
    ])
    test_dataset = datasets.ImageFolder(root=test_dir, transform=transform)
    test_loader = DataLoader(test_dataset, batch_size=batch_size, shuffle=False)
    return test_loader

def evaluate_model(model, data_loader, device):
    """
    Evaluate the model on the test dataset and compute accuracy and F-score.
    
    Args:
        model (torch.nn.Module): The trained model.
        data_loader (DataLoader): DataLoader for the test dataset.
        device (torch.device): Device to perform computation on.

    Returns:
        float: Top-1 Accuracy of the model on the test dataset.
        float: Top-5 Accuracy of the model on the test dataset.
        float: F1-Score of the model on the test dataset.
        list: True labels.
        list: Predicted labels.
        list: Top-5 predicted labels.
    """
    correct_top1 = 0
    correct_top5 = 0
    total = 0
    all_preds = []
    all_labels = []
    all_top5_preds = []

    with torch.no_grad():
        for inputs, labels in data_loader:
            inputs = inputs.to(device)
            labels = labels.to(device)
            outputs = model(inputs)

            # Top-1 Accuracy
            _, predicted = torch.max(outputs.data, 1)
            correct_top1 += (predicted == labels).sum().item()

            # Top-5 Accuracy
            maxk = 5
            _, top5_pred = outputs.topk(maxk, 1, True, True)
            top5_pred = top5_pred.t()
            correct = top5_pred.eq(labels.view(1, -1).expand_as(top5_pred))
            correct_top5 += correct[:5].reshape(-1).float().sum(0, keepdim=True).item()

            total += labels.size(0)
            all_preds.extend(predicted.cpu().numpy())
            all_labels.extend(labels.cpu().numpy())
            all_top5_preds.extend(top5_pred.cpu().numpy())

    top1_accuracy = 100 * correct_top1 / total
    top5_accuracy = 100 * correct_top5 / total
    f1 = f1_score(all_labels, all_preds, average='weighted')

    return top1_accuracy, top5_accuracy, f1, all_labels, all_preds

def plot_confusion_matrix(true_labels, pred_labels, classes):
    """
    Plot a confusion matrix using seaborn.
    
    Args:
        true_labels (list): True class labels.
        pred_labels (list): Predicted class labels.
        classes (list): List of class names.
    """
    from sklearn.metrics import confusion_matrix
    cm = confusion_matrix(true_labels, pred_labels)
    plt.figure(figsize=(10,8))
    sns.heatmap(cm, annot=True, fmt='d', xticklabels=classes, yticklabels=classes, cmap='Blues')
    plt.xlabel('Predicted')
    plt.ylabel('True')
    plt.title('Confusion Matrix')
    plt.show()

def parse_arguments():
    """
    Parse command-line arguments.
    
    Returns:
        argparse.Namespace: Parsed command-line arguments.
    """
    parser = argparse.ArgumentParser(description='Evaluate model accuracy on a test dataset.')
    parser.add_argument('--test_dir', type=str, default='dataset/val',
                        help='Path to the test dataset directory (default: dataset/val)')
    parser.add_argument('--batch_size', type=int, default=64,
                        help='Batch size for DataLoader (default: 64)')
    parser.add_argument('--model_path', type=str, default='model_best.pth.tar',
                        help='Path to the trained model file (default: model_best.pth.tar)')
    args = parser.parse_args()
    return args

def main():
    args = parse_arguments()
    
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    model_path = args.model_path
    test_dir = args.test_dir
    batch_size = args.batch_size

    print(f'Preparing data loader for test directory: {test_dir}...')
    test_loader = get_data_loaders(test_dir, batch_size=batch_size)
    
    num_classes = len(test_loader.dataset.classes)
    print(f'Loading model from {model_path}...')
    model, checkpoint = load_model(model_path, device, num_classes)
    
    print('Evaluating model...')
    top1_accuracy, top5_accuracy, f1, true_labels, pred_labels = evaluate_model(model, test_loader, device)
    
    print(f'Top-1 Accuracy of the model on the test dataset: {top1_accuracy:.2f}%')
    print(f'Top-5 Accuracy of the model on the test dataset: {top5_accuracy:.2f}%')
    print(f'F1-Score of the model on the test dataset: {f1:.2f}')
    
    # Assuming class indices are stored in checkpoint
    if 'class_to_idx' in checkpoint:
        classes = list(checkpoint['class_to_idx'].keys())
    else:
        # If not available, get from dataset
        test_dataset = datasets.ImageFolder(root=test_dir)
        classes = test_dataset.classes
    
    print('Plotting confusion matrix...')
    plot_confusion_matrix(true_labels, pred_labels, classes)
    
    # Optional: Print classification report
    print('Classification Report:')
    print(classification_report(true_labels, pred_labels, target_names=classes))

if __name__ == '__main__':
    main()
