function [tout,yout]  = sodecl( platform, device, kernel, initx, params, solver, orbits, nequat, nparams, nnoi, dt, tspan, ksteps, localgroupsize )
%SODECL Interface for using the odecl solvers in MATLAB.
%
% Syntax:  [tout,yout] = SODECL( platform, device, kernel, initx, params, solver, orbits, nequat, nparams, nnoi, dt, tspan, ksteps )
%
% Inputs:
%   platform    - OpenCL platform number
%   device      - OpenCL device number of selected platform
%   kernel      - ODE or SDE system kernel filename
%   initx       - Initial conditions for each orbit for the ODE system
%   params      - Parameters sets for the ODE system for all orbits
%   solver      - ODE or SDE solver
%   orbits      - Number of orbits to be integrated
%   nequat      - Number of equations of the ODE system
%   nparams     - Number of parameter of the ODE system
%   nnoi        - Number of noise processes
%   dt          - ODE or SDE solver time step size
%   tspan       - Integration time span
%   ksteps      - Number of ODE or SDE integrations executed in each OpenCL kernel call
%
%
% Outputs:
%   yout - Time output
%   yout - Model output
%
% Example:
%   [tout,yout]  = sodecl( 3 0 broomhead.cl x_y0.bin x_params.bin 2 512 6 6 1e-5 6 40)
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
% Other dependencies: odecl executable
%
% See also: E. Avramidis & O.E. Akman. Optimisation of an exemplar oculomotor model
% using multi-objective genetic algorithms executed on a GPU-CPU combination.
% BMC Syst. Biol., 11: 40 (2017)
%
% $Author: Eleftherios Avramidis $
% $Email: el.avramidis@gmail.com $
% $Date: 2016/07/25 $
% $Version: 0.1 $
% Copyright: MIT License
% tic

delete('t.bin');
delete('sodecloutput.bin');
delete('x_params.bin');
delete('x_t0.bin');
delete('x_y0.bin');
delete('sodecllog.txt');
delete('sodeclexitstatus.txt');

nparams=nparams+nnoi;

% Write parameters and initial conditions to files

% dlmwrite('x_y0.txt', initx, 'delimiter', '\t','precision',10);
fileID = fopen('x_y0.bin','w');
fwrite(fileID,initx','double');
fclose(fileID);

t0=0;
x_t0=repmat(t0, orbits, 1);

% dlmwrite('x_t0.txt', x_t0, 'delimiter', '\t','precision',10);
fileID = fopen('x_t0.bin','w');
fwrite(fileID,x_t0','double');
fclose(fileID);

% dlmwrite('x_params.txt', params, 'delimiter', '\t','precision',10);
fileID = fopen('x_params.bin','w');
fwrite(fileID,params','double');
fclose(fileID);

switch solver
    case 'se'
        odesolver=0;
    case 'e'
        odesolver=1;
    case 'r'
        odesolver=2;
    case 'ie'
        odesolver=3;
    case 'im'
        odesolver=4;
    otherwise
        odesolver=0;
end

['start /affinity 3 /wait sodeclexe.exe ' num2str(platform) ' ' num2str(device) ... 
    ' ' kernel ' ' 'x_y0.bin' ' '  'x_params.bin' ' ' num2str(odesolver) ...
    ' ' num2str(orbits) ' ' num2str(nequat) ' ' num2str(nparams) ' ' num2str(nnoi) ...
    ' ' num2str(dt) ' ' num2str(tspan) ' ' num2str(ksteps) ' ' num2str(localgroupsize)]
[s w] = dos(['sodeclexe.exe ' num2str(platform) ' ' num2str(device) ... 
    ' ' kernel ' ' 'x_y0.bin' ' '  'x_params.bin' ' ' num2str(odesolver) ...
    ' ' num2str(orbits) ' ' num2str(nequat) ' ' num2str(nparams) ' ' num2str(nnoi) ...
    ' ' num2str(dt) ' ' num2str(tspan) ' ' num2str(ksteps) ' ' num2str(localgroupsize)], '-echo');
if s
    disp(' Call to SODECL failed')
    return
end


% get the results
yout=getresults('sodecloutput.bin', orbits);
tout=0:dt:(length(yout)-1)*dt;

