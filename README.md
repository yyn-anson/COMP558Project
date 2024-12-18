# COMP558Project
This is a final course project of COMP 558 (Computer Vision).

# Usage

## MLV Implementation
The Bernhardt-Walther Lab at the University of Toronto created a MLV ToolBox GitHub repository. This toolbox provided us with the ability to analyze medial axes and perceptual organization cues. We have produced following test-files that used the codebase:

testing_LD_MAT.m - Creates line drawing & Computes MAT (outputting both images)

testing_Properties.m  - Computes MAT feature scores and outputs all heat map visuals

testing_5050.m - Calls our created function new_drawSplitMATproperty to create contour splits of specified feature

new_drawSplitMATproperty -  Created to divides pixels of an image into top 50% (high scores) and bottom 50% (low scores) based on the magnitude of the feature scores. This took the 5 images of each property (including our additional property) and produced 3 images for each (a total of 15): a line drawing with only the bottom 50% values visible (surrounded with a blue border), a line drawing with only the top 50% values visible (surrounded with a red border) and a line drawing with all values (bottom values colored blue, top values colored red. The function was modified to have an adjustable percentage to be more flexible (allow for different splits analysis)
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

## Reference:
1. MLV toolbox
   bwlabToronto/MLV_toolbox
github.com
2. Contour/LineDrawing dataset given by Dirk Warther's lab
   https://osf.io/9squn/
3. Pytorch Example
   https://github.com/pytorch/examples/tree/main/imagenet
