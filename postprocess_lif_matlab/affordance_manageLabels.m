% manage annotations for CAD-120 dataset for affordances
function[] = affordance_manageLabels()
    
    clc; clear all; close all;
    opts.floc='/media/data/projectData/affordance_structured_random_forest/pylabelme/data/';
    opts.wloc='/media/data/projectData/CornellDataset/processed_data/affordance_dataset/';
    opts.flist=dir([opts.floc '/*.lif']);
    opts.flist={opts.flist.name};
    opts.objlist={'table','kettle','plate','milk',...
                  'bottle','knife','medicinebox','can',...
                  'microwave','box','bowl','cup'};
    opts.allaffs={'openable','cuttable','containable','pourable','supportable','holdable'};
    opts.afflist={{'supportable'},...
                  {'holdable','pourable'},...
                  {'holdable','supportable'},...
                  {'holdable','openable'},...
                  {'holdable','openable'},...
                  {'holdable','cuttable'},...
                  {'holdable','openable'},...
                  {'holdable','pourable'},...
                  {'openable','containable','supportable'},...
                  {'holdable','openable'},...
                  {'holdable','containable'},...
                  {'holdable','containable','pourable'}};
    opts.affMap=containers.Map(opts.allaffs,1:numel(opts.allaffs));
    opts.erode=1;

    for fidx=1:numel(opts.flist)
        fname=[opts.floc opts.flist{fidx}];
        wname=[opts.wloc opts.flist{fidx}(1:end-3) 'mat'];
        data=loadjson(fname);
        img=imread([fname(1:end-3) 'png']);
        img_label=0*img(:,:,1);
        obj_labels=zeros(size(img,1),size(img,2),numel(opts.objlist));

        for oidx=1:numel(opts.objlist)
           for aidx=1:numel(opts.afflist{oidx})
              for sidx=1:numel(data.shapes)
                  split=strsplit(data.shapes{sidx}.label,'_');
                  if(strcmp(split{1},opts.objlist{oidx}) && strcmp(split{2},opts.afflist{oidx}{aidx}))
                      points=data.shapes{sidx}.points;
                      bw=roipoly(img,points(:,1),points(:,2));
                      img_label(bw>0)=opts.affMap(opts.afflist{oidx}{aidx});

                      % individual object labels
                      temp=obj_labels(:,:,oidx);
                      temp(bw>0)=opts.affMap(opts.afflist{oidx}{aidx});
                      obj_labels(:,:,oidx)=temp;
                  end
              end
           end
        end        
        
%         % get individual object bounding boxes
%         bb_list = getObjectBoundingBoxes(opts,obj_labels);
%         % edit the bounding box list
%         bb_list = editBoundingBoxes(img,bb_list,fidx,numel(opts.flist));
%         % save single label per pixel
%         save(wname,'img_label','bb_list');
        
        % load labels
        load(wname);
        % display affordances, object bbs
        subplot(2,2,1); imshow(img); title(sprintf('%i out of %i',fidx,numel(opts.flist)));
        subplot(2,2,2); imshow(img);
        
        for oidx=1:numel(bb_list)
            for bbidx=1:size(bb_list{6},1)
                rectangle('Position',bb_list{6}(bbidx,:),'EdgeColor','r');
            end
        end
        subplot(2,2,3); imagesc(img_label,[0,numel(opts.afflist)]);
        pause(0.1);
    end
end


function bb_list_new = editBoundingBoxes(img,bb_list,fidx,num_files)
    bb_list_new={};
    for oidx=1:numel(bb_list)
        bb_list_new{oidx}=[];
        for bbidx=1:size(bb_list{oidx},1)
            set(gcf,'Position',[500 500 400 300])
            imshow(img); title(sprintf('%i out of %i',fidx,num_files));
            h=imrect(gca,bb_list{oidx}(bbidx,:));
            bb_new = wait(h);
            if(bb_new(4)<=350), bb_list_new{oidx}=[bb_list_new{oidx}; bb_new]; end;
        end
    end
end

function bb_list = getObjectBoundingBoxes(opts,obj_labels)
    
    bboffset=opts.erode*[-1 -1 2 2];
    for oidx=1:numel(opts.objlist)
        if(~any(obj_labels(:,:,oidx))), bb_list{oidx}=[]; continue; end;
        origBwImg=obj_labels(:,:,oidx);
        origBwImg(origBwImg>0)=1;
        
        if(strcmp(opts.objlist{oidx},'bowl') || strcmp(opts.objlist{oidx},'cup') || ...
           strcmp(opts.objlist{oidx},'plate') || strcmp(opts.objlist{oidx},'box') || ...
           strcmp(opts.objlist{oidx},'bottle') || strcmp(opts.objlist{oidx},'table'))
                
                bwimg=imclose(origBwImg,strel('disk',2*opts.erode));
%                 bwimg=imerode(origBwImg,strel('disk',opts.erode));
                bwimg=imdilate(origBwImg,strel('disk',opts.erode));
                conncomp=bwconncomp(bwimg);
                bb=[];
                for ccidx=1:numel(conncomp.PixelIdxList)
                    [rloc,cloc]=ind2sub(size(obj_labels(:,:,oidx)),conncomp.PixelIdxList{ccidx});
                    bb=[bb; [min(cloc) min(rloc) max(cloc)-min(cloc) max(rloc)-min(rloc)]+bboffset]; 
                end
        else
           [rloc cloc]=find(origBwImg>0); 
           bb=[min(cloc) min(rloc) max(cloc)-min(cloc) max(rloc)-min(rloc)];
        end
        
        bb_list{oidx}=bb;
    end
end


% flist=dir('/media/data/projectData/CornellDataset/processed_data/affordance_dataset/*.mat');
% rpath='/media/data/projectData/CornellDataset/processed_data/affordance_dataset/';
% imgrpath='/media/data/projectData/CornellDataset/';
% wpath='/media/data/projectData/CornellDataset/processed_data/temp/';
% flist={flist.name};
% 
% fid=fopen([wpath 'filenames_map.txt'],'w');
% for fidx=1:numel(flist)
%     display(sprintf('%d',fidx));
%     fname=flist{fidx};
%     anno=load([rpath fname]);
%     gt_label=double(anno.img_label);
%     gt_bblist=anno.bb_list;
%     gt_type='manual';
%     wname=[wpath num2str(10000+fidx)];
% 
%     rgbfname=[imgrpath fname(1:end-3) 'png'];
%     if(~isempty(strfind(rgbfname,'Subject1')) || ~isempty(strfind(rgbfname,'Subject3')) ||...
%             ~isempty(strfind(rgbfname,'Subject4')) || ~isempty(strfind(rgbfname,'Subject5')))
%         rgbfname=strrep(rgbfname,'-','/');
%         depfname=strrep(rgbfname,'RGB','Depth');
%     else
%         rgbfname=strrep(rgbfname,'-','/');
%         depfname=strrep(rgbfname,'frame','depth/frame');
%     end
%     imgrgb=imread(rgbfname);
%     imgdep=imread(depfname);
%     save([wname '.mat'],'gt_label','gt_bblist','gt_type');
%     imwrite(imgrgb,[wname '_RGB.png'],'png');
%     imwrite(imgdep,[wname '_Depth.png'],'png');
%     fprintf(fid,'%i\t%s\t%s\n',fidx,fname,wname);
% end
% fclose(fid);