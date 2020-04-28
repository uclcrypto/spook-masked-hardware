
localparam spook_sbox_nbits=4;
localparam spook_sbox_nands=4;
localparam spook_sbox_multdepth=2;
localparam spook_sbox_refdepth=1;
localparam spook_sbox_lat= spook_sbox_multdepth + spook_sbox_refdepth;
localparam spook_sbox_tot_size= d * spook_sbox_nbits;
localparam spook_sbox_rnd= spook_sbox_nands * d*(d-1)/2;
localparam and_pini_lat_1 = d*(d-1)/2;
