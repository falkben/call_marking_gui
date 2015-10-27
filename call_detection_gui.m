function varargout = call_detection_gui(varargin)
% CALL_DETECTION_GUI MATLAB code for call_detection_gui.fig
%      CALL_DETECTION_GUI, by itself, creates a new CALL_DETECTION_GUI or raises the existing
%      singleton*.
%
%      H = CALL_DETECTION_GUI returns the handle to a new CALL_DETECTION_GUI or the handle to
%      the existing singleton*.
%
%      CALL_DETECTION_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CALL_DETECTION_GUI.M with the given input arguments.
%
%      CALL_DETECTION_GUI('Property','Value',...) creates a new CALL_DETECTION_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before call_detection_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to call_detection_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help call_detection_gui

% Last Modified by GUIDE v2.5 27-Oct-2015 15:10:15

% Wu-Jung Lee | leewujung@gmail.com
% 2015 10 24  change to to read in/save mic signals and detection results
%             separately so that the original data are not duplicted


% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @call_detection_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @call_detection_gui_OutputFcn, ...
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
% End initialization code - DO NOT EDIT


% --- Executes just before call_detection_gui is made visible.
function call_detection_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to call_detection_gui (see VARARGIN)

% Choose default command line output for call_detection_gui
handles.output = hObject;

% Enable figure toolbar
set(hObject,'toolbar','figure');

% Link plotting axes
linkaxes([handles.axes_spectrogram,handles.axes_time_series],'x');

% Set zoom and pan motion
gui_op.hzoom = zoom;
% setAxesZoomMotion(gui_op.hzoom,handles.axes_spectrogram,'horizontal');
% setAxesZoomMotion(gui_op.hzoom,handles.axes_time_series,'horizontal');

gui_op.hpan = pan;
% setAxesPanMotion(gui_op.hpan,handles.axes_spectrogram,'horizontal');
% setAxesPanMotion(gui_op.hpan,handles.axes_time_series,'horizontal');

% set(gui_op.hzoom,'ActionPostCallback',{@myzoomcallback});
% set(gui_op.hpan,'ActionPostCallback',{@mypancallback});


% Update handles structure
guidata(hObject, handles);

% Save global var
data = [];
setappdata(0,'data',data);
setappdata(0,'gui_op',gui_op);
setappdata(0,'handles_op',handles);


% UIWAIT makes call_detection_gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = call_detection_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in button_load_file.
function button_load_file_Callback(hObject, eventdata, handles)
% hObject    handle to button_load_file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Select file to load
[fname,pname] = uigetfile('*.mat','Select signal file');
k = strfind(fname,'_detect');
if isempty(k)  % if not '_detect' file
    ss = strsplit(fname,'.');
    fname_det = [ss{1},'_detect.mat'];
    fname_sig = fname;
else
    fname_det = fname;
    fname_sig = fname(1:k-1);
end

hmsg = msgbox('Loading signal, it''s big so be patient...','Load signal','Warn');
disp(['Loading file: ',fname,', please wait...']);

% Load detection results
if exist([pname,fname_det],'file')
    D_det = load([pname,fname_det]);
    % copy all fields into current data structure
    field_in_file = fieldnames(D_det);
    for iF=1:length(field_in_file)
        data.(field_in_file{iF}) = D_det.(field_in_file{iF});
    end
end

% Load mic signal
D_sig = load([pname,fname_sig]);
field_in_file = fieldnames(D_sig);
for iF=1:length(field_in_file)
    data.(field_in_file{iF}) = D_sig.(field_in_file{iF});
end

if exist('hmsg','var')
    close(hmsg)
end
disp('Signal loaded!');

% patch for num_ch_in_file
data.num_ch_in_file = size(data.sig,2);
disp(['Number of channels in file: ',num2str(data.num_ch_in_file)]);

% patch for sig_t
if ~isfield(data,'sig_t')
    data.sig_t = (0:length(data.sig)-1)/data.fs;
else
    if isempty(data.sig_t)
        data.sig_t = (0:length(data.sig)-1)/data.fs;
    end
end

data.fname = fname_sig;
data.pname = pname;

setappdata(0,'data',data);

% if ~isfield(data,'call') % if not previously saved results
%     data.fname = fname_sig;
%     data.pname = pname;
%     setappdata(0,'data',data);
% else
%     gui_op.chsel_current = data.chsel;  % keep track of the current channel being displayed
% end

if isfield(data,'call') % if previously saved results
    gui_op.chsel_current = data.chsel;  % keep track of the current channel being displayed
end

chsel_gui;  % update data and gui_op inside this function

if exist('gui_op','var')
    setappdata(0,'gui_op',gui_op);
end



% --- Executes on button press in button_detect_call.
function button_detect_call_Callback(hObject, eventdata, handles)
% hObject    handle to button_detect_call (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

data = getappdata(0,'data');
% detecting calls if not previously saved results
if ~isfield(data,'call') % if not previously saved results
    disp('No previous detection, proceed to threshold data >>>');
    data.locs = th_detection(data.sig(:,data.chsel),data.fs);
    setappdata(0,'data',data);
    initialize_call_param();
else
    disp('Previous detection loaded!');
end
set(handles.edit_curr_ch,'String',num2str(data.chsel));

plot_spectrogram(handles,1);



% --- Executes on button press in button_ch_next.
function button_ch_next_Callback(hObject, eventdata, handles)
% hObject    handle to button_ch_next (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = getappdata(0,'data');
gui_op = getappdata(0,'gui_op');
hh = getappdata(0,'handles_op');

tmp = mod(gui_op.chsel_current+1,data.num_ch_in_file);
if tmp==0
    gui_op.chsel_current = data.num_ch_in_file;
else
    gui_op.chsel_current = tmp;
end
set(hh.edit_curr_ch,'String',num2str(gui_op.chsel_current));

setappdata(0,'gui_op',gui_op);

plot_spectrogram(hh);  % update spectrogram and time series


% --- Executes on button press in button_channel_previous.
function button_channel_previous_Callback(hObject, eventdata, handles)
% hObject    handle to button_channel_previous (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = getappdata(0,'data');
gui_op = getappdata(0,'gui_op');
hh = getappdata(0,'handles_op');

tmp = mod(gui_op.chsel_current-1,data.num_ch_in_file);
if tmp==0
    gui_op.chsel_current = data.num_ch_in_file;
else
    gui_op.chsel_current = tmp;
end
set(hh.edit_curr_ch,'String',num2str(gui_op.chsel_current));

setappdata(0,'gui_op',gui_op);

plot_spectrogram(hh);  % update spectrogram and time series


% --- Executes on button press in button_add_mark.
function button_add_mark_Callback(hObject, eventdata, handles)
% hObject    handle to button_add_mark (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = getappdata(0,'data');
gui_op = getappdata(0,'gui_op');
hh = getappdata(0,'handles_op');


tolerance = round(2e-3*data.fs);  % tolerence in points
[xadd,~] = ginput(1);   % time
xadd = round(xadd/1e3*data.fs);  % convert time to index
if any(abs([data.call.locs]-xadd)<tolerance)  % prevent marking error
    xadd = [];
end
if ~isempty(xadd)
    data.call(end+1).locs = xadd;  % append at the end, will sort when done with file
end

% update figure
set(gui_op.mark_spectrogram,'XData',[data.call.locs]/data.fs*1e3,'YData',50*ones(1,length(data.call)));
set(gui_op.mark_time_series,'XData',[data.call.locs]/data.fs*1e3,'YData',zeros(1,length(data.call)));

% initialize call parameter estimates
iC = length(data.call);

data.call(iC).channel_marked = gui_op.chsel_current;  % record which channel the call is marked on
data.call(iC).bandwidth = nan(1,2);
data.call(iC).bandwidth_ch = gui_op.chsel_current;
data.call(iC).duration_caxis = nan(1,2);
data.call(iC).duration_ch = gui_op.chsel_current;
data.call(iC).low_quality = 0;

th_dura_sec = 5e-3;    % [s]
ext_idx = data.call(iC).locs + (round(-th_dura_sec*data.fs):round(th_dura_sec*data.fs));
ext_idx(ext_idx<1|ext_idx>size(data.sig,1)) = [];

sig_curr = data.sig(ext_idx,gui_op.chsel_current);
call_idx = est_call_start_end(sig_curr);

data.aux_data(iC).ext_idx = ext_idx;
data.aux_data(iC).call_idx = call_idx;
data.call(iC).call_start_idx = call_idx(1)+ext_idx(1);
data.call(iC).call_end_idx = call_idx(2)+ext_idx(1);

% save global var
setappdata(0,'data',data);
setappdata(0,'gui_op',gui_op);



% --- Executes on button press in button_remove_mark.
function button_remove_mark_Callback(hObject, eventdata, handles)
% hObject    handle to button_remove_mark (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% load global var
data = getappdata(0,'data');
gui_op = getappdata(0,'gui_op');
hh = getappdata(0,'handles_op');

% stop pan or zoom motion
setAllowAxesZoom(gui_op.hzoom,hh.axes_spectrogram,0);
setAllowAxesZoom(gui_op.hzoom,hh.axes_time_series,0);
setAllowAxesPan(gui_op.hpan,hh.axes_spectrogram,0);
setAllowAxesPan(gui_op.hpan,hh.axes_time_series,0);

% circle the marks to remove
k = waitforbuttonpress;
p1 = get(hh.axes_spectrogram,'CurrentPoint');
rect = rbbox;
p2 = get(hh.axes_spectrogram,'CurrentPoint');
pp = sort([p1(1,1) p2(1,1)])/1e3*data.fs;
current_locs = [data.call.locs];
del_idx = find(current_locs>pp(1)&current_locs<pp(2));

% delete call structure entry
data.call(del_idx) = [];
data.aux_data(del_idx) = [];

% update figure
set(gui_op.mark_spectrogram,'XData',[data.call.locs]/data.fs*1e3,'YData',50*ones(1,length(data.call)));
set(gui_op.mark_time_series,'XData',[data.call.locs]/data.fs*1e3,'YData',zeros(1,length(data.call)));

% restore pan or zoom motion
setAllowAxesZoom(gui_op.hzoom,hh.axes_spectrogram,1);
setAllowAxesZoom(gui_op.hzoom,hh.axes_time_series,1);
setAllowAxesPan(gui_op.hpan,hh.axes_spectrogram,1);
setAllowAxesPan(gui_op.hpan,hh.axes_time_series,1);

% save global var
setappdata(0,'data',data);
setappdata(0,'gui_op',gui_op);



% --- Executes on button press in button_done.
function button_done_Callback(hObject, eventdata, handles)
% hObject    handle to button_done (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% load global var
data = getappdata(0,'data');
gui_op = getappdata(0,'gui_op');
hh = getappdata(0,'handles_op');

% sort call according to call.locs
[~,IX] = sort([data.call.locs]);
call_sorted = data.call;
[call_sorted(:)] = deal(data.call(IX));
aux_data_sorted = data.aux_data;
[aux_data_sorted(:)] = deal(data.aux_data(IX));

% prepare for saving results
A.fname = data.fname;
A.pname = data.pname;
% A.sig = data.sig;
% A.sig_t = data.sig_t;
A.fs = data.fs;
A.sig_rough = data.sig_rough;
A.sig_rough_t = data.sig_rough_t;
A.shift_gap = data.shift_gap;
A.chsel = data.chsel;
A.num_ch_in_file = data.num_ch_in_file;
A.call = call_sorted;
A.aux_data = aux_data_sorted;

tt = strsplit(A.fname,'.mat');
save_fname = sprintf('%s_detect.mat',tt{1});
[save_fname,save_pname] = uiputfile('*.mat','Save detection results',[A.pname,'/',save_fname]);
save([save_pname,'/',save_fname],'-struct','A');



function edit_curr_ch_Callback(hObject, eventdata, handles)
% hObject    handle to edit_curr_ch (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = getappdata(0,'data');
gui_op = getappdata(0,'gui_op');
hh = getappdata(0,'handles_op');

tmp = mod(str2num(get(hh.edit_curr_ch,'String')),data.num_ch_in_file);
if tmp==0
    gui_op.chsel_current = data.num_ch_in_file;
else
    gui_op.chsel_current = tmp;
end
set(hh.edit_curr_ch,'String',num2str(gui_op.chsel_current));

setappdata(0,'gui_op',gui_op);

plot_spectrogram(hh);  % update spectrogram and time series

% Hints: get(hObject,'String') returns contents of edit_curr_ch as text
%        str2double(get(hObject,'String')) returns contents of edit_curr_ch as a double


% --- Executes during object creation, after setting all properties.
function edit_curr_ch_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_curr_ch (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function slider_caxis_Callback(hObject, eventdata, handles)
% hObject    handle to slider_caxis (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = getappdata(0,'data');
hh = getappdata(0,'handles_op');
caxis(hh.axes_spectrogram,...
      [data.curr_caxis_range(1)+range(data.curr_caxis_range)*get(hh.slider_caxis,'value'),...
       data.curr_caxis_range(2)]);

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function slider_caxis_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider_caxis (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% close secondary GUI figure
hh2 = getappdata(0,'handles_ch_sig');
if isfield(hh2,'figure1')
    delete(hh2.figure1);
end

% delete global var
if isappdata(0,'data')
    rmappdata(0,'data');
end
if isappdata(0,'gui_op')
    rmappdata(0,'gui_op');
end
if isappdata(0,'handles_op')
    rmappdata(0,'handles_op');
end
if isappdata(0,'handles_ch_sig')
    rmappdata(0,'handles_ch_sig');
end

% Hint: delete(hObject) closes the figure
delete(hObject);




%%% ================= OTHER FUNCTIONS ===============================



function locs = th_detection(sig_current,sig_fs)
% perform simple signal detection
th_pi = inputdlg('Minimum pulse interval threshold (ms):','Threshold',1,{'15'});
th_pi = cellfun(@(c) str2num(c),th_pi);

% manually select threshold for detection
fig_th = figure('toolbar','figure');
set(fig_th,'units','pixel','position',[100 100 1100 550]);
th_flag = 0;
while th_flag == 0
    plot(sig_current);
    [~,th_pk] = ginput(1);
    [pks,locs] = findpeaks(sig_current,'minpeakheight',th_pk,...
        'minpeakdistance',fix(th_pi*1e-3*sig_fs));
    hold on
    hpks = plot(locs,pks,'r*');
    button = questdlg('Accept this threshold?','Threshold','Yes','No','Yes');
    if strcmp(button,'Yes');
        th_flag = 1;
    else
        delete(hpks);
    end
end
close(fig_th)



function initialize_call_param()
data = getappdata(0,'data');
locs = data.locs;

total_call_num = length(locs);
data.call(total_call_num).locs = [];
locs = num2cell(locs);
[data.call(:).locs] = deal(locs{:});

channel_marked = num2cell(ones(total_call_num,1)*data.chsel);  % add 2015/02/13
[data.call(:).channel_marked] = deal(channel_marked{:});

data.call(total_call_num).bandwidth = [];
data.call(total_call_num).bandwidth_ch = [];
data.call(total_call_num).duration_ch = [];
data.call(total_call_num).duration_caxis = [];
data.call(total_call_num).low_quality = [];

tmp = num2cell(zeros(total_call_num,1));
[data.call(:).low_quality] = deal(tmp{:});

tmp = num2cell(ones(total_call_num,1)*data.chsel);
[data.call(:).bandwidth_ch] = deal(tmp{:});
[data.call(:).duration_ch] = deal(tmp{:});

tmp = cell(total_call_num,1);
tmp(:) = {nan(1,2)};
[data.call(:).bandwidth] = deal(tmp{:});
[data.call(:).duration_caxis] = deal(tmp{:});

for iC=1:total_call_num
    th_dura_sec = 5e-3;    % [s]
    ext_idx = data.call(iC).locs + (round(-th_dura_sec*data.fs):round(th_dura_sec*data.fs));
    ext_idx(ext_idx<1|ext_idx>size(data.sig,1)) = [];
    
    sig = data.sig(ext_idx,data.chsel);
    call_idx = est_call_start_end(sig);

    data.aux_data(iC).ext_idx = ext_idx;
    data.aux_data(iC).call_idx = call_idx;
    data.call(iC).call_start_idx = call_idx(1)+ext_idx(1);
    data.call(iC).call_end_idx = call_idx(2)+ext_idx(1);
end

setappdata(0,'data',data);


function call_idx = est_call_start_end(sig)
sm = smooth(sig.^2,10);
sm_log = smooth(10*log10(sm),50); % prevent spiking in the beginning
sm_log(1:10) = mean(sm_log(11:250));
n_log = mean(sm_log(1:250));
[~,midx] = max(sm_log);
midx = min([midx,length(sm_log)-1]);

if max(sm_log)-n_log>6  % minimum 6dB SNR
    fac_start = diff(sign(sm_log-(n_log+3)));
    fac_end = diff(sign(sm_log-(n_log+1)));
else
    fac_start = diff(sign(sm_log-(n_log)));
    fac_end = fac_start;
end
idx_start = find(fac_start(1:midx)==2,1,'last')+1;
idx_end = find(fac_end(midx:end)==-2,1,'first')+midx-1;
if ~isempty(idx_start)
    call_idx(1) = idx_start;
else
    call_idx(1) = 100;
end
if ~isempty(idx_end)
    call_idx(2) = idx_end;
else
    call_idx(2) = length(sm_log)-100;
end

sig = sig(call_idx(1):call_idx(2));
e = smooth(sig.^2,round(length(sig)/4));
[me,midx] = max(e);
tmp = find(e(midx:end)<me*0.001,1,'first');
if ~isempty(tmp)
    call_idx(2) = tmp+call_idx(1)+midx-2;
else
    call_idx(2) = call_idx(2);
end



function plot_spectrogram(handles,varargin)
data = getappdata(0,'data');
gui_op = getappdata(0,'gui_op');
hh = getappdata(0,'handles_op');
hh_ch_sig = getappdata(0,'handles_ch_sig');

if nargin==2 && varargin{1}==1
    flag = 1;
else
    flag = 0;
end

% determine ranges to calculate spectrogram
if flag==1  % first time plotting spectrogram
    pt_range = [1,size(data.sig,1)];
    gui_op.hzoom = zoom;
    gui_op.hpan = pan;
else
    xlim_curr = xlim(handles.axes_spectrogram);
    pt_range = (range(xlim_curr)+1)/1e3*data.fs;  % [points]
    pt_range = round(xlim_curr/1e3*data.fs + pt_range*[-1 1]);
    if pt_range(1)<1
        pt_range(1) = 1;
    end
    if pt_range(2)>size(data.sig,1)
        pt_range(2) = size(data.sig,1);
    end
end

pt_range = pt_range(1):pt_range(2);

% calculate spectrogram
pt_len_sec = range(pt_range)+1;  % length of data to be calculated
pt_len_fft = max([2.^(nextpow2(pt_len_sec/1000)-1),128]);
pt_len_overlap = round(pt_len_fft*0.9);
[~,F,T,P] = spectrogram(data.sig(pt_range,gui_op.chsel_current),...
                        pt_len_fft,pt_len_overlap,pt_len_fft,data.fs);
P = 10*log10(abs(P));
if ~exist('xlim_curr')
	xlim_curr = T([1 end])*1e3;
end
                    
% plot spectrogram =============================
axes(handles.axes_spectrogram);
gui_op.image_spectrogram = imagesc(T*1e3+pt_range(1)/data.fs*1e3,F/1e3,P);
axis xy
% if flag==1  % first time plot spectrogram
hold on
gui_op.mark_spectrogram = plot([data.call.locs]/data.fs*1e3,50,'m*','markersize',10,'linewidth',1.5);
hold off
% else
%     set(gui_op.image_spectrogram,'CData',P,'XData',T*1e3+pt_range(1)/data.fs*1e3,'YData',F/1e3);
%     set(gui_op.mark_spectrogram,'XData',[data.call.locs]/data.fs*1e3,'YData',50*ones(length(data.call),1));
% end
ylabel('Frequency (kHz)');
xlim(xlim_curr);

% scale color axis
data.curr_caxis_range = [min(min(P)) max(max(P))];
caxis(handles.axes_spectrogram,...
      [data.curr_caxis_range(1)+range(data.curr_caxis_range)*get(handles.slider_caxis,'value'),...
       data.curr_caxis_range(2)]);

   
% plot times series =============================
axes(handles.axes_time_series)
if flag==1
    gui_op.line_time_series = plot(data.sig_t*1e3,data.sig(:,gui_op.chsel_current));
    hold on
    gui_op.mark_time_series = plot([data.call.locs]/data.fs*1e3,0,'m*','markersize',10,'linewidth',1.5);
    hold off
    ylabel(handles.axes_time_series,'Voltage (V)');
    xlabel(handles.axes_time_series,'Time (ms)');
else
    set(gui_op.line_time_series,'XData',data.sig_t*1e3,'YData',data.sig(:,gui_op.chsel_current));
    set(gui_op.mark_time_series,'XData',[data.call.locs]/data.fs*1e3,'YData',zeros(length(data.call),1));
end
xlim(xlim_curr);

% set zoom and pan motion
setAxesZoomMotion(gui_op.hzoom,handles.axes_spectrogram,'horizontal');
setAxesZoomMotion(gui_op.hzoom,handles.axes_time_series,'horizontal');

setAxesPanMotion(gui_op.hpan,handles.axes_spectrogram,'horizontal');
setAxesPanMotion(gui_op.hpan,handles.axes_time_series,'horizontal');

set(gui_op.hzoom,'ActionPostCallback',{@myzoomcallback});
set(gui_op.hpan,'ActionPostCallback',{@mypancallback});

% update figure in secondary GUI
axes(hh_ch_sig.axes_ch_sig);
if flag == 1
    hold on
    gui_op.ch_sig_line1 = plot(xlim_curr(1)/1e3*[1 1],[-1 (data.num_ch_in_file+1)*data.shift_gap+1],'k--');
    gui_op.ch_sig_line2 = plot(xlim_curr(2)/1e3*[1 1],[-1 (data.num_ch_in_file+1)*data.shift_gap+1],'k--');
    hold off
else
    set(gui_op.ch_sig_line1,'XData',xlim_curr(1)/1e3*[1 1]);
    if range(xlim_curr)/1e3>0.01
        set(gui_op.ch_sig_line2,'XData',xlim_curr(2)/1e3*[1 1]);
    else
        set(gui_op.ch_sig_line2,'XData',[-1 -1]);
    end
end
axes(hh.axes_spectrogram);

    
% save global var
setappdata(0,'data',data);
setappdata(0,'gui_op',gui_op);




function myzoomcallback(obj,evd)
% newLim = get(evd.Axes,'XLim');
% msgbox(sprintf('The new X-Limits are [%.2f %.2f].',newLim));% handles_op = getappdata();
hh = getappdata(0,'handles_op');
plot_spectrogram(hh);
% disp('zoomcallback')

function mypancallback(obj,evd)
hh = getappdata(0,'handles_op');
plot_spectrogram(hh);
% disp('pancallback')