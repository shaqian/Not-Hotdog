from pycocotools.coco import COCO
import numpy as np
import skimage.io as io
import matplotlib.pyplot as plt
import os
from shutil import copyfile

category = 'hot dog'
classId = 0
dataDir='.'
dataType='val2014'

annFile = '{}/annotations/instances_{}.json'.format(dataDir,dataType)
imgDir = '{}/{}'.format(dataDir,dataType)

exportDir = category.replace(' ', '') + '/' + dataType
os.makedirs(exportDir, exist_ok=True)

coco=COCO(annFile)

cats = coco.loadCats(coco.getCatIds())
nms=[cat['name'] for cat in cats]
print('COCO categories: \n{}\n'.format(' '.join(nms)))

nms = set([cat['supercategory'] for cat in cats])
print('COCO supercategories: \n{}'.format(' '.join(nms)))

catIds = coco.getCatIds(catNms=[category]);
print('COCO category id for {}: {}'.format(category, catIds))

imgIds = coco.getImgIds(catIds=catIds );
imgs = coco.loadImgs(imgIds)

for img in imgs: 
    fileName = img["file_name"]
    imgPath = imgDir + '/' + fileName
    newPath = exportDir + '/' + fileName
    txtFile = exportDir + '/' + os.path.splitext(fileName)[0] + '.txt'
    copyfile(imgPath, newPath)
    # print(newPath)
    dw = 1. / img['width']
    dh = 1. / img['height']
    annIds = coco.getAnnIds(imgIds=img['id'], catIds=catIds, iscrowd=None)
    anns = coco.loadAnns(annIds)
    with open(txtFile, 'w+') as file:
        for ann in anns:
            box = ann["bbox"]
            x = box[0] + box[2]/2
            y = box[1] + box[3]/2
            w = box[2]
            h = box[3]
            x = round(x * dw, 3)
            w = round(w * dw, 3)
            y = round(y * dh, 3)
            h = round(h * dh, 3)
            str = "{} {} {} {} {}\n".format(classId, x, y, w, h)
            # print(str)
            file.write(str)
