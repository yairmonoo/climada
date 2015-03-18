function IFC = climada_hazard2IFC(hazard,geo_locations)
% climada
% NAME:
%   climada_hazard2IFC
% PURPOSE:
%   Obtains the intensity frequency curve (IFC) of a given hazard set. 
%   See climada_IFC_plot to plot the IFC structure.
%
%   Subsequent call: climada_IFC_plot
% CALLING SEQUENCE:
%   climada_hazard2IFC(hazard,geo_locations)
% EXAMPLE:
%   climada_hazard2IFC(hazard,[23 94 51])
%   geo_locations.lon=14.426;geo_locations.lat=40.821;
%   climada_hazard2IFC('',geo_locations)
% INPUTS:
%   hazard: A climada hazard set.
% OPTIONAL INPUT PARAMETERS:
%   geo_location: if not given, centroid ID is set to 1. 
%       Can be either: a 1xN vector of centroid_IDs;  Or a structure with
%       fields .lon and .lat to specificy coordinates of interest, i.e. 
%       geo_locations.lon=14.426;geo_locations.lat=40.821;
% OUTPUTS:
%   IFC: A structure to be used as input to climada_IFC_plot,
%       containing information about the intensity-frequency
%       properties of a given hazard
% MODIFICATION HISTORY:
% Gilles Stassen, gillesstassen@hotmail.com, 20150130
% David N. Bresch, david.bresch@gmail.com, 20150309, bugfixes
% Lea Mueller, muellele@gmail.com, 20150318, fit parameters only for
%                                            positive intensity values
%-

IFC = []; % init

global climada_global
if ~climada_init_vars                , return            ; end % init/import global variables
if ~exist('hazard'            ,'var'), hazard        = []; end
if ~exist('geo_locations'     ,'var'), geo_locations = []; end

% prompt for hazard if not given
if isempty(hazard) % local GUI
    hazard=climada_hazard_load;
end

% prompt for centroid ID if not given
if isempty(geo_locations)
    geo_locations = 1;
    fprintf('Centroid_ID set to %d. Please specify otherwise, if required. \n',geo_locations)
end

% if input is a centroid ID
if isvector(geo_locations) && ~isstruct(geo_locations)
    poi_ID  = sort(geo_locations);
    poi_ndx = find(ismember(hazard.centroid_ID, poi_ID));
    % does not work for multiple centroid IDs
    %poi_ID  = geo_locations;
    %poi_ndx = find(hazard.centroid_ID == poi_ID); 
end
    
% if input has centroids structure
if isstruct(geo_locations)
    poi_lon = geo_locations.lon;
    poi_lat = geo_locations.lat;
    r = climada_geo_distance(poi_lon, poi_lat,hazard.lon,hazard.lat);
    [~, poi_ndx] = min(r);
    poi_ID  = hazard.centroid_ID(poi_ndx);
end
    

no_generated = hazard.event_count / hazard.orig_event_count;

% initiate IFC 
IFC.hazard_comment     = hazard.comment;
IFC.peril_ID           = hazard.peril_ID;
IFC.centroid_ID        = poi_ID;

IFC.intensity          = zeros(numel(poi_ID), hazard.event_count);
IFC.return_periods     = zeros(numel(poi_ID), hazard.event_count);

%IFC.DFC_return_periods = climada_global.DFC_return_periods;
IFC.DFC_return_periods = [1:1:100 120:20:200 250:50:1000];
IFC.intensity_fit      = zeros(numel(poi_ID), numel(IFC.DFC_return_periods));
IFC.polyfit            = zeros(numel(poi_ID), 2);

IFC.hist_intensity     = zeros(numel(poi_ID), hazard.orig_event_count);
IFC.hist_return_periods= zeros(numel(poi_ID), hazard.orig_event_count);


% calculate for each point of interest
for poi_i = 1:numel(poi_ID)
    %1: intensity
    [IFC.intensity(poi_i,:),int_ndx] = sort(full(hazard.intensity(:,poi_ndx(poi_i))),'descend');
    %IFC.orig_event_flag = hazard.orig_event_flag(int_ndx);
    
    %frequency
    IFC.return_periods(poi_i,:) = 1./cumsum(hazard.frequency(int_ndx));
    %IFC(poi_i).cum_event_freq = cumsum(hazard.frequency(int_ndx).*(no_generated+1));
    
    %2: fitted intensity for given return periods
    rel_indx = IFC.intensity(poi_i,:)>0;
    IFC.polyfit(poi_i,:)       = polyfit(log10(IFC.return_periods(poi_i,rel_indx)), IFC.intensity(poi_i,rel_indx), 1);
    IFC.intensity_fit(poi_i,:) = polyval(IFC.polyfit(poi_i,:), log10(IFC.DFC_return_periods));
    
    %historic data only
    ori_indx = logical(hazard.orig_event_flag);
    [IFC.hist_intensity(poi_i,:),int_ndx] = sort(full(hazard.intensity(ori_indx,poi_ndx(poi_i))),'descend');
    IFC.hist_return_periods(poi_i,:) = 1./cumsum(hazard.frequency(int_ndx)*no_generated);

    %fit a Gumbel-distribution
    %8: exceedence frequency
    %IFC.return_freq = 1./climada_global.DFC_return_periods;
    %6: intensity for given return periods
    %IFC.intensity_rp(poi_i,:) = polyval(IFC.polyfit(poi_i,:), log(IFC.return_period));
    %7: intensity prob.
    %IFC.return_polyfit(poi_i,:) = polyfit(log(IFC.cum_event_freq(poi_i,:)), IFC.intensity(poi_i,:), 1);
    %IFC.return_polyval(poi_i,:) = polyval(IFC.return_polyfit(poi_i,:), log(IFC.return_freq(poi_i,:)));
end
IFC.intensity_fit(IFC.intensity_fit<0) = 0;

end % climada_hazard2IFC



