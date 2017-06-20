function varargout = NewMBD(opts)
% NEWMBD - Script to programatically build a new basic model for the 
%	DescriptionLine1
%	DescriptionLine2
%	DescriptionLine3
%	DescriptionLine4
%
% Syntax:
%	NewMBD()
%
% Inputs:
%	options - Structure with input options.
%
% Outputs:
%   default_options - If called with 1 output and no inputs.
%
%   Otherwise: No output.
%
% Example:
%	NewMBD()
%
%   opts = NewMBD()
%   opts.model_name = "NewModel"
%   NewMBD(opts)
%

% Author: Jed Frey
% June 2017

%------------- BEGIN CODE --------------

% Model name
defaults.model_name='mbdModel';
% Create init script
defaults.create_init=true;
% Create build script
defaults.create_build=true;
% Target
defaults.target='mbd_pnt.tlc';
% Target MCU
defaults.target_mcu='MPC5744P';
% Location to S32 install directory.
defaults.S32_root = 'C:\Freescale\S32_Power_v1.1';

% If no inputs and only 1 output return the default options.
% Used to easily get a struct of what is available.
if nargin==0 && nargout==1
   varargout{1} = defaults;
   return    
end

%% IO Processing
% Process input
switch nargin
    case 0
        % If no input arguments are given, set the options to the default.
        opts=defaults;
    case 1
        % Otherwise get all of the fieldnames from the default settings.
        fields = fieldnames(defaults);
        % Determine all of the unset fields.
        unset_fields = fields(~isfield(opts,fields));
        % For each of the unset fields assign the default to opts struct.
        for i = 1:numel(unset_fields)
            field=unset_fields{i};
            opts.(field) = defaults.(field);
        end
end

%% New Model
% Get the model name from the options.
% First converting it into a valid matlab name, if it isn't already.
mdl = matlab.lang.makeValidName(opts.model_name);
% Create a new model.
mdl_h = new_system(mdl);
% Open the model
open_system(mdl);
% Get the active configuration set.
myConfigObj = getActiveConfigSet(mdl);
% Change the system target file for the configuration set.
switchTarget(myConfigObj,opts.target,[]);
% Set the target MCU.
myConfigObj.set_param('target_mcu', opts.target_mcu)

%% Add Blocks
% Platform config block
block = '/MBD_MPC574xP_Config_Information';
config_block = add_block(['mbd_pnt_ec_toolbox/MPC574xP' block], [mdl block]);

% Set the location for the block
x0 = 20;
y0 = 20;
% Set the size for the block.
height = 160;
width  = height*1.61803398875; % Golden ratio. For aesthetics. 
% Move the config block to location w/size.
set(config_block, 'Position', [x0, y0, x0+width, y0+height]);

% Add simple digital read/write.

% Location and Size for digital read/write.
x0 = 20;
y0 = 300;
height = 64;
width  = 256;

block = '/Digital_Input';
digital_in = add_block(['mbd_pnt_ec_toolbox/MPC574xP/Peripheral Interface Blocks' block], [mdl block]);
set(digital_in, 'Position', [x0, y0, x0+width, y0+height]);
% Set the default port.
set(digital_in, 'gpio_outputs', '0     : A0   :  [73]   : [86]   : [P12]');

% Move the x0 location.
x0 = 400;
block = '/Digital_Output';
digital_out = add_block(['mbd_pnt_ec_toolbox/MPC574xP/Peripheral Interface Blocks' block], [mdl block]);
set(digital_out, 'Position', [x0, y0, x0+width, y0+height]);
set(digital_out, 'gpio_outputs', '1     : A1   :  [74]   : [91]   : [T14]');

% Connect blocks.
digital_in_ports = get(digital_in, 'PortHandles');
digital_out_ports = get(digital_out, 'PortHandles');
add_line(mdl, digital_in_ports.Outport, digital_out_ports.Inport)

% Model settings that make development easier.
simulinkDisplay(mdl);
% Zoom to all blocks
set_param(mdl, 'ZoomFactor','FitSystem')
% Update the model.
set_param(mdl, 'SimulationCommand', 'update')

% Save the system.
save_system(mdl);
% Create an Init.
if opts.create_init
    init_out=sprintf('%s_init.m',get_param(mdl,'name'));
    fid=fopen(init_out, 'w');
    fprintf(fid,'%% MBD Init\n');
    fprintf(fid, 'setenv(''S32DS_PA_TOOL'', ''%s'');', opts.S32_root);
    fclose(fid);
end
% Create build script, if asked.
if opts.create_build
    build_out=sprintf('%s_build.m',get_param(mdl,'name'));
    fid=fopen(build_out, 'w');
    fprintf(fid,'cd(fileparts(mfilename(''fullpath'')))\n');
    fclose(fid);
end
%------------- END CODE ----------------

function simulinkDisplay(model)
% simulinkDisplay(model) - enable commonly used formatting settings in simulink models.
%   model - model to use. Otherwise use output from 'bdroot'.
%
%  These are all settings that I've discovered improve development by
%  explicitly showing what is going on in a model.
%
%  http://www.mathworks.com/help/simulink/slref/model-parameters.html
%  WideLines - Enable
%  ShowPortDataTypes - Enable
%  ShowStorageClass -  Enable
%  ShowLineDimensions - Enable
%  LibraryLinkDisplay - All
%  SampleTimeColors - Enabled
%  SampleTimeAnnotations - Enabled 
if nargin<1
    model=bdroot;
else
    model=bdroot(model);
end
set_param(model,'WideLines','on')
set_param(model,'ShowPortDataTypes','on')
set_param(model,'ShowStorageClass','on')
set_param(model,'ShowTestPointIcons','on')
set_param(model,'ShowLineDimensions','on')
set_param(model,'LibraryLinkDisplay','all')
set_param(model,'SampleTimeColors','on')
set_param(model,'SampleTimeAnnotations','on')
