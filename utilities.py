import os
import os.path

def returnFiles(dirloc,filetag):
    filelist=[]
    for dirpath, dirnames, filenames in os.walk(dirloc):
        for filename in [f for f in filenames if f.endswith(filetag)]:
            filelist.append(os.path.join(dirpath, filename))
    
    filelist.sort()
    return filelist