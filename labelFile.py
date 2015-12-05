#
# Copyright (C) 2011 Michael Pitidis, Hussein Abdulwahid.
#
# This file is part of Labelme.
#
# Labelme is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Labelme is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Labelme.  If not, see <http://www.gnu.org/licenses/>.
#

import json
import os.path

from base64 import b64encode, b64decode

class annotation:
    def __init__(self,obj_name,aff_name,bb_string):
        self.obj_name=obj_name
        self.aff_name=aff_name
        bb=map(int,bb_string.split(" "))
        self.shape=[]
        self.shape.append(('bb',[[bb[0],bb[1]],[bb[0],bb[1]+bb[3]],\
        [bb[0]+bb[2],bb[1]+bb[3]],[bb[0]+bb[2],bb[1]]],None,None))

class LabelFileError(Exception):
    pass

class AnnoFileError(Exception):
    pass

class LabelFile(object):
    suffix = '.lif'

    def __init__(self, filename=None, read_mode=0):
        self.shapes = ()
        self.imagePath = None
        self.imageData = None
        if filename is not None:
            self.load_anno(filename)
        if filename is not None and read_mode is 0:
            self.load(filename)
            
    def load_anno(self,filename):
        try:
            # load annotation data
            fid=open(filename[:-3]+"txt",'rb')
            tanno=[row.strip().split('\t') for row in fid]
            self.anno=[]
            for lanno in tanno:
                self.anno.append(annotation(lanno[0],lanno[1],lanno[2]))
        except Exception, e:
            raise AnnoFileError(e)

    def load(self, filename):
            
        try:
            with open(filename, 'rb') as f:
                data = json.load(f)
                imagePath = data['imagePath']
                imageData = b64decode(data['imageData'])
                lineColor = data['lineColor']
                fillColor = data['fillColor']
                shapes = ((s['label'], s['points'], s['line_color'], s['fill_color'])\
                        for s in data['shapes'])
                # Only replace data after everything is loaded.
                self.shapes = shapes
                self.imagePath = imagePath
                self.imageData = imageData
                self.lineColor = lineColor
                self.fillColor = fillColor
        except Exception, e:
            raise LabelFileError(e)

    def save(self, filename, shapes, imagePath, imageData,
            lineColor=None, fillColor=None):
        try:
            with open(filename, 'wb') as f:
                json.dump(dict(
                    shapes=shapes,
                    lineColor=lineColor, fillColor=fillColor,
                    imagePath=imagePath,
                    imageData=b64encode(imageData)),
                    f, ensure_ascii=True, indent=2)
        except Exception, e:
            raise LabelFileError(e)

    @staticmethod
    def isLabelFile(filename):
        return os.path.splitext(filename)[1].lower() == LabelFile.suffix

