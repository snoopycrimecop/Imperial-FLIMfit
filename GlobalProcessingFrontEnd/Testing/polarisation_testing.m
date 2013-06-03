function deconv_magic = polarisation_testing(data_series,default_path)

% Copyright (C) 2013 Imperial College London.
% All rights reserved.
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License along
% with this program; if not, write to the Free Software Foundation, Inc.,
% 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
%
% This software tool was developed with support from the UK 
% Engineering and Physical Sciences Council 
% through  a studentship from the Institute of Chemical Biology 
% and The Wellcome Trust through a grant entitled 
% "The Open Microscopy Environment: Image Informatics for Biological Sciences" (Ref: 095931).

% Author : Sean Warren
    
    decay = data_series.data_series;
    irf = data_series.irf;
        
    decay = sum(decay,3);
    decay = sum(decay,4);
    
    t = data_series.t;
    t_irf = data_series.t_irf;
    
    para = squeeze(decay(:,1,:,:));
    perp = squeeze(decay(:,2,:,:));
    
    irf_para = squeeze(irf(:,1));
    irf_perp = squeeze(irf(:,2));
    
    n = length(para);
        
    global gf;
    if isempty(gf)
        gf = figure();
    end
    
    figure(gf);
    
    
    c_para = conv(para,irf_perp,'full');
    c_perp = conv(perp,irf_para,'full');
    c_irf  = conv(irf_perp,irf_para,'full');
    
    %{
    range = 1:length(c_para);
    
    c_para = c_para(range);
    c_perp = c_perp(range);
    c_irf = c_irf(range);
    %}
    
    c_r = (c_para - c_perp) ./ (c_para + 2 * c_perp);
    
    %{
    subplot(4,1,1)
    plot([c_para c_perp c_irf/max(c_irf)*max(c_perp)])
    %}
    
    c_magic = c_para + 2 * c_perp; 
    
    c_magic = c_magic / max(c_magic) * 32000;
    c_magic = uint16(c_magic);

    c_irf = c_irf / max(c_irf) * 32000;
    c_irf = uint16(c_irf);

    
    %c_magic = c_magic(n/2:(end-n/2));
    %c_irf = c_irf(n/2:(end-n/2));
    
    dt = t(2) - t(1);
    
    tn = 0:(length(c_magic)-1);
    tn = tn * dt;
    
    subplot(4,1,2)
    plot(c_irf)

    subplot(4,1,3)
    semilogy(c_magic)
    
    
    
    
    data = [tn' c_magic];
    dlmwrite([default_path '\000_combined_pol.txt'],data,'\t');
    
    data = [tn' c_irf];
    dlmwrite([default_path '\000_combined_irf.txt'],data,'\t');
    
    
    subplot(4,1,4)
    %{
    c_magic = [zeros(n*3,1); c_magic; zeros(n*3,1)];
    c_magic_taper = edgetaper(c_magic,c_irf);
    
    
    %d = deconvlucy(c_magic_taper,c_irf,100);
    d = deconvlucy(c_magic_taper,c_irf,200);
    
    %d = d((n*3)+1:(n*4));
    
    %deconv_magic = interp1(t,d,t_irf);
    
    semilogy(d);
%}
    
end