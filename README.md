# COMP558Project
This is a final course project of COMP 558 (Computer Vision).

# Usage
## Train a model
Example:
```bash
python main.py --pretrained [dataset-folder with train and val folders] --epochs 2 --batch-size 32 --lr 0.01
```

## Test a model
Example:
```bash
python test.py --test_dir ../dataset/LD_dataset/val --model_path ./model_best.pth.tar --batch_size 128
```
Replace `../dataset/LD_dataset/val` with the path to your test dataset.

## Please follow the dataset structure, the label name should be the same as the folder name.
Dataset structure:
   dataset/
       val/
           class1/
               image1.jpg
               image2.jpg
               ...
           class2/
               image1.jpg
               image2.jpg
               ...
           ...

