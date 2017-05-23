
%%%%%%%%%%%%%%%
%MAIN FUNCTION%
%%%%%%%%%%%%%%%

function varargout = gui_mia(varargin)

warning('off','all'); % desactivate warnings in order to avois spamming the command screen
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @gui_mia_OpeningFcn, ...
                   'gui_OutputFcn',  @gui_mia_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end


    
%%%%%%%%%%%%%%%%%%%
%END MAIN FUNCTION%
%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%
%OPENNING FUNCTION%
%%%%%%%%%%%%%%%%%%%

function gui_mia_OpeningFcn(hObject, eventdata, handles, varargin)
%Opening of the GUI

% Choose default command line output for mia_app
handles.output = hObject;

handles.sizeRegions=54;

handles.currentSegmentImage=3;

% Update handles structure
guidata(hObject, handles);


%%%%%%%%%%%%%%%%%%%%%%%
%END OPENNING FUNCTION%
%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%
%CLOSING FUNCTION%
%%%%%%%%%%%%%%%%%%
function varargout = gui_mia_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;

%%%%%%%%%%%%%%%%%%%%%%
%END CLOSING FUNCTION%
%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%
%BROWSER BUTTON FUNCTION%
%%%%%%%%%%%%%%%%%%%%%%%%%
function Browse_Callback(hObject, eventdata, handles)
%On click on the Browse button to select and open files
%Everything is filtered or can be filtered

[filenames, path, filterindex] = uigetfile( ...
{  '*.*',  'All Files (*.*)'}, ...
   'Pick a file', ...
   'MultiSelect', 'on');
%Read all the dicom images in order to make the list in the listbox and
%beeing able to display attributes that are in the DICOM images format
filenames=cellstr(filenames);
%Try Jpeg
isjpg=1;
try
info = imfinfo(fullfile(path,char(filenames)));
isjpg = strcmp(info.Format, 'jpeg');
catch
end

if (length(filenames) > 1 || isjpg ~= 0)
    isjpg = 1;
else
    info = imfinfo(fullfile(path,char(filenames)));
    isjpg = strcmp(info.Format, 'jpeg');
end


%Ability of checking if jpeg
%Only display the image and change the values of the gui show
if(isjpg == 0)
    X = imread([path,char(filenames)]);
    imshow(X, [], 'Parent', handles.imageViewer);
    
    %Set all the values of the first image selected in the UI
    set(handles.lastname,'String','-');
    set(handles.firstname,'String','-');
    set(handles.id,'String','-');
    set(handles.birth,'String','-');
    set(handles.study_id,'String','-');
    set(handles.study_date,'String','-');
    set(handles.slice,'String','-');
    set(handles.instance,'String','-');
    set(handles.listImages,'String',filenames);

    set(handles.listImages,'Value',1);
    
    msgbox('Selected Image is JPEG');
    
else
    [X, map] = dicomread([path filenames{1,1}]);
    imshow(X, [], 'Parent', handles.imageViewer);
    for i=1:size(filenames,2)
        info(i) = dicominfo([path filenames{1,i}]);
    end

    %Set all the values of the first image selected in the UI
    set(handles.lastname,'String',info(1).PatientName.FamilyName);
    set(handles.firstname,'String',info(1).PatientName.GivenName);
    set(handles.id,'String',info(1).PatientID);
    set(handles.birth,'String',info(1).PatientBirthDate);
    set(handles.study_id,'String',info(1).StudyID);
    set(handles.study_date,'String',info(1).StudyDate);
    set(handles.slice,'String',info(1).SliceLocation);
    set(handles.instance,'String',info(1).InstanceNumber);
    set(handles.listImages,'String',filenames);

    set(handles.listImages,'Value',1);
    
    

    %Extract the path for the starting point of other functions and also the
    %names of the files 
    handles.info=info;
    handles.path=path;
    handles.filenames=filenames;
    
    %Initialize big vectors to ensure to have enough space ( used to avoid
    %bug of memory / loss of values XY for the 3D Drawing)
    handles.ZPxCoordinates = zeros(1000 , numel(get(handles.listImages,'string')));
    handles.ZPyCoordinates = zeros(1000 , numel(get(handles.listImages,'string')));
    
    handles.ZCxCoordinates = zeros(1000 , numel(get(handles.listImages,'string')));
    handles.ZCyCoordinates = zeros(1000 , numel(get(handles.listImages,'string')));
    
    handles.ZTxCoordinates = zeros(1000 , numel(get(handles.listImages,'string')));
    handles.ZTyCoordinates = zeros(1000 , numel(get(handles.listImages,'string')));
    
    handles.TUxCoordinates = zeros(1000 , numel(get(handles.listImages,'string')));
    handles.TUyCoordinates = zeros(1000 , numel(get(handles.listImages,'string')));
    guidata(hObject, handles);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%END BROWSER BUTTON FUNCTION%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%
%PREVIOUS BUTTON FUNCTION%
%%%%%%%%%%%%%%%%%%%%%%%%%%
function prevButton_Callback(hObject, eventdata, handles)
%On click on the pevious button, if this s possible, change to the previous image
%Take care of the minimum index value (1)


%Create the index to be able to identify the position
currentIndex=get(handles.listImages,'Value');

%Conditionning avoiding out of boundaries
if currentIndex > 1
    nextIndex=currentIndex-1;
else
    nextIndex = currentIndex;
end

set(handles.listImages,'Value',nextIndex);
h = findobj('Tag','listImages');
%Change visually and phisically the image in the list box
listImages_Callback(h, eventdata, handles);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%END PREVIOUS BUTTON FUNCTION%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%
%NEXT BUTTON FUNCTION%
%%%%%%%%%%%%%%%%%%%%%%
function nextButton_Callback(hObject, eventdata, handles)
%On click on the next button, if this s possible, change to the next image
%Take care of the maximum index value


%Create the index to be able to identify the position
currentIndex=get(handles.listImages,'Value');

%Conditionning avoiding out of boundaries
if currentIndex == numel(get(handles.listImages,'string')) 
    nextIndex = currentIndex;
else
    nextIndex=currentIndex+1;
end

%Change the target
set(handles.listImages,'Value',nextIndex);
handles.currentSegmentImage=handles.currentSegmentImage+1;
guidata(hObject, handles);
h = findobj('Tag','listImages');
%Call of the list, to have the visual and physical switch on the list box
%(mean, changement also of values on the ui disoplay)
listImages_Callback(h, eventdata, handles);
%%%%%%%%%%%%%%%%%%%%%%%%%%
%END NEXT BUTTON FUNCTION%
%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%HANDLER IMAGE LIST FUNCTION%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function listImages_Callback(hObject, eventdata, handles)
%List of selected image handler
%After clicking on the browse button crate a list of images and display
%them in the list
%For each selected item able to change and modify the display of attributes
%on the UI

index_selected = get(hObject,'Value');
%Create a list of iamge eleents
list = get(hObject,'String');
%Create the dicom map to work with after with the ui
[X, map] = dicomread([handles.path list{index_selected}]);
%Display the selected imahe through X created just before
imshow(X, [], 'Parent', handles.imageViewer);

%Set the attributes in the UI Display
set(handles.lastname,'String',handles.info(index_selected).PatientName.FamilyName);
set(handles.firstname,'String',handles.info(index_selected).PatientName.GivenName);
set(handles.id,'String',handles.info(index_selected).PatientID);
set(handles.birth,'String',handles.info(index_selected).PatientBirthDate);
set(handles.study_id,'String',handles.info(index_selected).StudyID);
set(handles.study_date,'String',handles.info(index_selected).StudyDate);
set(handles.slice,'String',handles.info(index_selected).SliceLocation);
set(handles.instance,'String',handles.info(index_selected).InstanceNumber);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%END HANDLER IMAGE LIST FUNCTION%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%ANONYMIZE BUTTON FUNCTION%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
function anonimizeButton_Callback(hObject, eventdata, handles)
%On click on anonymize button
%Take all the selected images and anonymize them
%Take care of path and create a new folder to store the images
%Modify the image attributes and then change the working folder to the
%anonymous one
%Modify the display of the attributes on the UI

%Trying to take care of already existing anonymized folder.
for j = 0 : 10
    myfolder = ['anonymized',num2str(j) ,'/' ];
    A = exist(myfolder);
    if (A == 7)
        myfolder = myfolder;
    else
        break;
    end
end

%Taking the path and changing it
newpath=[handles.path myfolder];
%Removing the backslash from the folder name to abvoid duplicates
myfolder=strrep(myfolder,'/','');
%For each images info
%Change the informations and write a new DICOM 
for i=1:size(handles.info,2)
    handles.info(i).PatientName.FamilyName='';
    handles.info(i).PatientName.GivenName='';
    handles.info(i).PatientID='';
    handles.info(i).PatientBirthDate='';
    mkdir([handles.path myfolder]);
    [X, map] = dicomread(handles.info(i).Filename);
    h = findobj('Tag','listImages');
    list = get(h,'String');
    dicomwrite(X, [newpath list{i}], handles.info(i));
end
%end for each image infos

%Change the path name
handles.path=newpath;
%Reading all the image through paths
[X, map] = dicomread([handles.path handles.filenames{1,1}]);
imshow(X, [], 'Parent', handles.imageViewer);
handles = rmfield(handles, 'info');
for i=1:size(handles.filenames,2)
    handles.info(i) = dicominfo([handles.path handles.filenames{1,i}]);
end

%Set all the attributes dispolayed to be the new ones ANONYMIZED
set(handles.lastname,'String','-');
set(handles.firstname,'String','-');
set(handles.id,'String','-');
set(handles.birth,'String','-');
set(handles.study_id,'String',handles.info(1).StudyID);
set(handles.study_date,'String',handles.info(1).StudyDate);
set(handles.slice,'String',handles.info(1).SliceLocation);
set(handles.instance,'String',handles.info(1).InstanceNumber);
set(handles.listImages,'String',handles.filenames);
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%
%END ANONYMIZE FUNCTION%
%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%CONVERT TO JPEG BUTTON FUNCTION%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ConvertToJpeg_Callback(hObject, eventdata, handles)
%On click on JPEG conversion button
%Find the object in the list that is selected
h = findobj('Tag','listImages');
%Get the index of the selected item in the list items
index_selected = get(h,'Value');
%Get the string value of the image (aka the name)
name = get(h,'String');
%read the dicom according to the select index
[X, map] = dicomread([handles.path name{index_selected}]);
%Convert the x matrix into grayscale 
X = mat2gray(X);
%Write and convert the X matrix as jpegn, using the informations extracted
%before such as the name, the number 
imwrite(X,[handles.path name{index_selected} '.jpeg'], 'Quality',100,'Mode','lossy');
%Explanation of the imwrite as jpeg 
%There is a problem into this kind of sentence  but it speed up the
%process.
%Till we use Quality attribute and set it as 100 we can think that is it a
%lossless format (we dont loose information) but it's wrong, we are using
%the Mode Lossy so we will loose basic informations, for example when we
%want a really really precise work we should use lossless mode.
%In our case we use Lossy to speed uop the process but still we are using
%the maximum quality of this mode. For such processing it increase the
%speed and reduce the loss of informations.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%END CONVERT TO JPEG BUTTON FUNCTION%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% --- Executes on button press in DrawZP.
function DrawZP_Callback(hObject, eventdata, handles)
%Draw free hand and ezxtract xy coordinates of the line drawed, then
%calculate surface

index = get(handles.listImages,'Value');

%draw free hand
hFH = imfreehand();
% Get the xy coordinates of where they drew.
sizem = size(hFH);
handles.ZPxy = zeros(sizem);
handles.ZPxy = hFH.getPosition;
% get rid of imfreehand remnant.
delete(hFH);
% Overlay what they drew onto the image.
hold on; % Keep image, and direction of y axis.
size(handles.ZPxy,1);
%handles.ZPxCoordinates = zeros(size(handles.ZPxy,1) , 2);
handles.ZPxCoordinates(1:size(handles.ZPxy,1) , index) = handles.ZPxy(:, 1 ); % Extract the X coordinates from the previous xy
%handles.ZPyCoordinates = zeros(size(handles.ZPxy,1) , 2);
handles.ZPyCoordinates(1:size(handles.ZPxy,1) , index) = handles.ZPxy(:, 2 );% extract the Y coordinatees from the xy
plot(handles.ZPxCoordinates(1:size(handles.ZPxy,1) , index), handles.ZPyCoordinates(1:size(handles.ZPxy,1) , index), 'blue', 'LineWidth', 2, 'MarkerSize', 10); % plot the drawing
hold off

Area_in_Pixel = polyarea(handles.ZPxCoordinates(1:size(handles.ZPxy,1) , index),handles.ZPyCoordinates(1:size(handles.ZPxy,1) , index)) % calculate the area according the the image
Pixel_Spacing = handles.info(index).PixelSpacing(1)% display the pixel spacing

Surface = Area_in_Pixel * Pixel_Spacing % calculate the real area

Slice_Thickness = handles.info(index).SliceThickness(1) % display the slice thickness for volume

Volume = Surface * Slice_Thickness % calculate the volume
guidata(hObject, handles);


% --- Executes on button press in DrawZT.
function DrawZT_Callback(hObject, eventdata, handles)
%Draw free hand and ezxtract xy coordinates of the line drawed, then
%calculate surface



index = get(handles.listImages,'Value');

%draw free hand
hFH = imfreehand();
% Get the xy coordinates of where they drew.
sizem = size(hFH);
handles.ZTxy = zeros(sizem);
handles.ZTxy = hFH.getPosition;
% get rid of imfreehand remnant.
delete(hFH);
% Overlay what they drew onto the image.
hold on; % Keep image, and direction of y axis.
size(handles.ZTxy,1);
%handles.ZTxCoordinates = zeros(size(handles.ZTxy,1) , 2);
handles.ZTxCoordinates(1:size(handles.ZTxy,1) , index) = handles.ZTxy(:, 1 ); % Extract the X coordinates from the previous xy
%handles.ZTyCoordinates = zeros(size(handles.ZTxy,1) , 2);
handles.ZTyCoordinates(1:size(handles.ZTxy,1) , index) = handles.ZTxy(:, 2 );% extract the Y coordinatees from the xy
plot(handles.ZTxCoordinates(1:size(handles.ZTxy,1) , index), handles.ZTyCoordinates(1:size(handles.ZTxy,1) , index), 'green', 'LineWidth', 2, 'MarkerSize', 10); % plot the drawing
hold off


Area_in_Pixel = polyarea(handles.ZTxCoordinates(1:size(handles.ZTxy,1) , index),handles.ZTyCoordinates(1:size(handles.ZTxy,1) , index)) % calculate the area according the the image
Pixel_Spacing = handles.info(index).PixelSpacing(1)% display the pixel spacing

Surface = Area_in_Pixel * Pixel_Spacing % calculate the real area

Slice_Thickness = handles.info(index).SliceThickness(1) % display the slice thickness for volume

Volume = Surface * Slice_Thickness % calculate the volume
guidata(hObject, handles);


% --- Executes on button press in DrawZC.
function DrawZC_Callback(hObject, eventdata, handles)
%Draw free hand and ezxtract xy coordinates of the line drawed, then
%calculate surface


index = get(handles.listImages,'Value');

%draw free hand
hFH = imfreehand();
% Get the xy coordinates of where they drew.
sizem = size(hFH);
handles.ZCxy = zeros(sizem);
handles.ZCxy = hFH.getPosition;
% get rid of imfreehand remnant.
delete(hFH);
% Overlay what they drew onto the image.
hold on; % Keep image, and direction of y axis.
size(handles.ZCxy,1);
handles.ZCxCoordinates(1:size(handles.ZCxy,1) , index) = handles.ZCxy(:, 1 ); % Extract the X coordinates from the previous xy
%handles.ZCyCoordinates = zeros(size(handles.ZCxy,1) , 2);
handles.ZCyCoordinates(1:size(handles.ZCxy,1) , index) = handles.ZCxy(:, 2 );% extract the Y coordinatees from the xy
plot(handles.ZCxCoordinates(1:size(handles.ZCxy,1) , index), handles.ZCyCoordinates(1:size(handles.ZCxy,1) , index), 'red', 'LineWidth', 2, 'MarkerSize', 10); % plot the drawing
hold off

Area_in_Pixel = polyarea(handles.ZCxCoordinates(1:size(handles.ZCxy,1) , index),handles.ZCyCoordinates(1:size(handles.ZCxy,1) , index)) % calculate the area according the the image
Pixel_Spacing = handles.info(index).PixelSpacing(1)% display the pixel spacing

Surface = Area_in_Pixel * Pixel_Spacing % calculate the real area

Slice_Thickness = handles.info(index).SliceThickness(1) % display the slice thickness for volume

Volume = Surface * Slice_Thickness % calculate the volume
guidata(hObject, handles);

% --- Executes on button press in DrawTumor.
function DrawTumor_Callback(hObject, eventdata, handles)
%Draw free hand and ezxtract xy coordinates of the line drawed, then
%calculate surface

index = get(handles.listImages,'Value');
%draw free hand
hFH = imfreehand();
% Get the xy coordinates of where they drew.
sizem = size(hFH);
handles.TUxy = zeros(sizem);
handles.TUxy = hFH.getPosition;
% get rid of imfreehand remnant.
delete(hFH);
% Overlay what they drew onto the image.
hold on; % Keep image, and direction of y axis.
size(handles.TUxy,1);
%handles.TUxCoordinates = zeros(size(handles.TUxy,1) , 2);
handles.TUxCoordinates(1:size(handles.TUxy,1) , index) = handles.TUxy(:, 1 ); % Extract the X coordinates from the previous xy
%handles.TUyCoordinates = zeros(size(handles.TUxy,1) , 2);
handles.TUyCoordinates(1:size(handles.TUxy,1) , index) = handles.TUxy(:, 2 );% extract the Y coordinatees from the xy
plot(handles.TUxCoordinates(1:size(handles.TUxy,1) , index), handles.TUyCoordinates(1:size(handles.TUxy,1) , index), 'white', 'LineWidth', 2, 'MarkerSize', 10); % plot the drawing
hold off


Area_in_Pixel = polyarea(handles.TUxCoordinates(1:size(handles.TUxy,1) , index),handles.TUyCoordinates(1:size(handles.TUxy,1) , index)) % calculate the area according the the image
Pixel_Spacing = handles.info(index).PixelSpacing(1)% display the pixel spacing

Surface = Area_in_Pixel * Pixel_Spacing % calculate the real area

Slice_Thickness = handles.info(index).SliceThickness(1) % display the slice thickness for volume

Volume = Surface * Slice_Thickness % calculate the volume

guidata(hObject, handles);

% --- Executes on button press in Modeling.
function Modeling_Callback(hObject, eventdata, handles)
figure
hold on
for i = 1 : numel(get(handles.listImages,'string'))
    XYZTu = [handles.TUxCoordinates(:, i)  handles.TUyCoordinates(:, i)  ones( size(handles.TUxCoordinates(:, i),1) , 1) * i * handles.info(i).SliceThickness(1) ];
    scatter3(XYZTu(: , 1) , XYZTu(: , 2) , XYZTu(: , 3) , 'filled');
    title('3D Modeling Tumor')
end
hold off

figure
hold on
for i = 1 : numel(get(handles.listImages,'string'))
    XYZZP = [handles.ZPxCoordinates(:, i)  handles.ZPyCoordinates(:, i)  ones( size(handles.ZPxCoordinates(:, i),1) , 1) * i * handles.info(i).SliceThickness(1) ];
    scatter3(XYZZP(: , 1) , XYZZP(: , 2) , XYZZP(: , 3) , 'filled');
end
title('3D Modeling ZP')
hold off

figure
hold on
for i = 1 : numel(get(handles.listImages,'string'))
    XYZZC = [handles.ZCxCoordinates(:, i)  handles.ZCyCoordinates(:, i)  ones( size(handles.ZCxCoordinates(:, i),1) , 1) * i * handles.info(i).SliceThickness(1) ];
    scatter3(XYZZC(: , 1) , XYZZC(: , 2) , XYZZC(: , 3) , 'filled');
end
title('3D Modeling ZC')
hold off

figure
hold on
for i = 1 : numel(get(handles.listImages,'string'))
    XYZZT = [handles.ZTxCoordinates(:, i)  handles.ZTyCoordinates(:, i)  ones( size(handles.ZTxCoordinates(:, i),1) , 1) * i * handles.info(i).SliceThickness(1) ];
    scatter3(XYZZT(: , 1) , XYZZT(: , 2) , XYZZT(: , 3) , 'filled');
end
title('3D Modeling ZT')
hold off

guidata(hObject, handles);
