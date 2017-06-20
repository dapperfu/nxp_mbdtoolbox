%  MBD_INIT Initializes MBD Toolbox paths.
%   MBD_INIT changes the MATLAB path to add the current MBD toolbox.
%
%   Examples
%       mbd_init()
%
% Copyright (c) 2017 Jed Frey
% All rights reserved.

function mbd_init(varargin)
    openModels = find_system('SearchDepth', 0);
    if numel(openModels)>0
       error('MBD_INIT:SIMULINK_OPEN', 'There are open simulink models. Please save them then run `bdclose(''all'')`.');
    end
    bdclose('all');
    mbd_root = fileparts(mfilename('fullpath'));

% Paths to add with full subdirectories.
recursive_paths = {
    fullfile(mbd_root, 'mbdtbx_pnt', 'src')
    fullfile(mbd_root, 'mbdtbx_pnt', 'MCLIB_pnt', 'bam')
    fullfile(mbd_root, 'mbdtbx_pnt', 'mbdtbx_pnt')
}';

% Paths to add as is.
bare_paths = {
    fullfile(mbd_root, 'mbdtbx_pnt')
    fullfile(mbd_root, 'mbdtbx_pnt', 'Examples')
    mbd_root
}';

% Add the recursive paths.
for recursive_path = recursive_paths
    addpath(genpath(recursive_path{1}));
end

% Add the bare paths.
for bare_path = bare_paths
    addpath(bare_path{1});    
end

% Rehash the toolbox cache
rehash toolboxcache;
% Refresh the simulink customizations.
sl_refresh_customizations();
start_simulink;
