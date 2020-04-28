
function integer _ref_lat_0(input integer d);
begin
if (d==2 || d== 3) _ref_lat_0 = d-1;
else if (d==4 || d==5) _ref_lat_0 = 0;
else if (d == 6) _ref_lat_0 = 0;
else if (d == 7) _ref_lat_0 = 0;
else if (d==8 || d==9) _ref_lat_0 = 0;
else if (d == 10) _ref_lat_0 = 0;
else if (d == 11) _ref_lat_0 = 0;
else if (d == 12) _ref_lat_0 = 0;
else if (d >= 13 && d <= 16) _ref_lat_0 = 0;
end
endfunction

function integer _ref_lat_m1(input integer d);
begin
if (d==2 || d== 3) _ref_lat_m1 = 0;
else if (d==4 || d==5) _ref_lat_m1 = d;
else if (d == 6) _ref_lat_m1 = d;
else if (d == 7) _ref_lat_m1 = d;
else if (d==8 || d==9) _ref_lat_m1 = d;
else if (d == 10) _ref_lat_m1 = d;
else if (d == 11) _ref_lat_m1 = d;
else if (d == 12) _ref_lat_m1 = d;
else if (d >= 13 && d <= 16) _ref_lat_m1 = 0;
end
endfunction

function integer _ref_lat_m2(input integer d);
begin
if (d==2 || d== 3) _ref_lat_m2 = 0;
else if (d==4 || d==5) _ref_lat_m2 = 0;
else if (d == 6) _ref_lat_m2 = 1;
else if (d == 7) _ref_lat_m2 = 2;
else if (d==8 || d==9) _ref_lat_m2 = 3;
else if (d == 10) _ref_lat_m2 = 5;
else if (d == 11) _ref_lat_m2 = 6;
else if (d == 12) _ref_lat_m2 = 8;
else if (d >= 13 && d <= 16) _ref_lat_m2 = 2*d;
end
endfunction

localparam ref_lat_0 = _ref_lat_0(d);
localparam ref_lat_m1 = _ref_lat_m1(d);
localparam ref_lat_m2 = _ref_lat_m2(d);
localparam ref_n_rnd = ref_lat_0 + ref_lat_m1 + ref_lat_m2;

