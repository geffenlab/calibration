function y = rms(x, dim)
% Copy of Matlab RMS function 

if nargin==1
  y = sqrt(mean(x .* conj(x)));
else
  y = sqrt(mean(x .* conj(x), dim));
end

