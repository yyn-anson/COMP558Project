import torch
import argparse

def fix_checkpoint(input_path, output_path):
    """
    Fix the state_dict by replacing 'features.module.' with 'features.'.

    Args:
        input_path (str): Path to the original checkpoint.
        output_path (str): Path to save the fixed checkpoint.
    """
    checkpoint = torch.load(input_path, map_location='cpu')
    
    if 'state_dict' not in checkpoint:
        raise KeyError("The checkpoint does not contain a 'state_dict' key.")
    
    state_dict = checkpoint['state_dict']
    fixed_state_dict = {}

    for key, value in state_dict.items():
        if key.startswith('features.module.'):
            new_key = key.replace('features.module.', 'features.')
            fixed_state_dict[new_key] = value
        else:
            fixed_state_dict[key] = value

    checkpoint['state_dict'] = fixed_state_dict
    torch.save(checkpoint, output_path)
    print(f"Fixed checkpoint saved to {output_path}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Fix checkpoint state_dict prefixes.')
    parser.add_argument('--input', type=str, required=True, help='Path to the original checkpoint (e.g., model_best.pth.tar)')
    parser.add_argument('--output', type=str, required=True, help='Path to save the fixed checkpoint (e.g., model_best_fixed.pth.tar)')
    args = parser.parse_args()
    
    fix_checkpoint(args.input, args.output)
