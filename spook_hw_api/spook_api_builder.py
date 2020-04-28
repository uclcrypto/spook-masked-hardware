
from math import ceil
import random
import numpy as np
import functools

from spook_hw_api import utils_api

class Spook_API_Builder:
    # Constant 
    SIZE_CMD_B = 4

    def __init__(self,L_ENDIAN=False,DSHARE=2,SEG_MAX_CMDS=8):
        # Configure the builder
        self.configure(L_ENDIAN=L_ENDIAN,DSHARE=DSHARE,SEG_MAX_CMDS=SEG_MAX_CMDS) 

    def configure(self,L_ENDIAN=False,DSHARE=2,SEG_MAX_CMDS=8):
        # Some API commands formatting parameters
        self.L_ENDIAN = L_ENDIAN
        self.DSHARE = DSHARE
        self.SEG_MAX_CMDS = SEG_MAX_CMDS
        self.CURRENT_BUILD=None
        self.reset_extract_status()

    def reset_extract_status(self):
        self.extract_status = []
        self.reset_extract_values()

    def reset_extract_values(self):
        self.extract_s0 = []
        self.extract_s1 = []
        self.extract_s2 = []
        self.extract_key = []
        self.extract_rec_key = []
        self.extract_ad = []
        self.extract_n = []
        self.extract_m = []
        self.extract_c = []
        self.extract_tag = []
        self.type_process = None

    # Build the set of commands for an 'Instruction'
    # return [set_size, set, flags]
    # with the size in term of amount of commands
    def __build_inst(self, opcode_s):
        opcode = 0
        if opcode_s=="encrypt":
            opcode = 2
        elif opcode_s=="decrypt":
            opcode = 3
        elif opcode_s=="loadkey":
            opcode = 4
        elif opcode_s=="ld_encrypt":
            opcode = 9
        elif opcode_s=="ld_decrypt":
            opcode = 10
        elif opcode_s=="ld_seed":
            opcode = 11
        elif opcode_s=="status_success":
            opcode = 14
        elif opcode_s=="status_failure":
            opcode = 15
        else:
            opcode = 0

        opcode_shiftl4 = opcode << 4
        inst = [utils_api.ext_bits(opcode_shiftl4,8),0,0,0]

        # Constant KEEP flag (sakura-g setup compliance)
        finst = self.SIZE_CMD_B*[0]

        if self.L_ENDIAN:
            inst.reverse()
            finst.reverse()

        # Update command status
        self.extract_status = self.extract_status + self.SIZE_CMD_B*['api_ctrl']

        return [1,bytes(inst),finst]

    # Build the set of commands
    # for an 'Header'
    # return [set_size, set, flags]
    # with the size in term of amount of commands
    def __build_header(self, dtype_s,eot,eoi,last,length,sel_nibble=0):
        dtype = 0
        if dtype_s == 'KEY':
            dtype = 12
        elif dtype_s == 'NPUB':
            dtype = 13
        elif dtype_s == 'AD':
            dtype = 1
        elif dtype_s == 'PT':
            dtype = 4
        elif dtype_s == 'CT':
            dtype = 5
        elif dtype_s == 'TAG':
            dtype = 8
        elif dtype_s == 'SEED':
            dtype = 9
        else:
            dtype = 0   

        head_info = dtype << 4
        if(eot):
            head_info = head_info + 4
        if(eoi):
            head_info = head_info + 2
        if(last):
            head_info = head_info + 1

        length_MSBits = (length >> 8) & 0xff
        length_LSBits = length & 0xff

        shifted_sel_nibble = ((sel_nibble << 4) + 1) & 0xff

        header = [head_info,shifted_sel_nibble,length_MSBits,length_LSBits]

        # Constant KEEP flag (sakura-g setup compliance)
        fhead = self.SIZE_CMD_B*[0]

        if self.L_ENDIAN:
            header.reverse()
            fhead.reverse()

        # Update command status
        self.extract_status = self.extract_status + self.SIZE_CMD_B*['api_ctrl']
        dtype_saved = dtype_s
        if dtype_saved == 'SEED':
            if sel_nibble==0:
                dtype_saved = 'SEED0'
            elif sel_nibble==1:
                dtype_saved = 'SEED1'
            elif sel_nibble==2:
                dtype_saved = 'SEED2'
        self.type_process = dtype_saved

        return [1,bytes(header),fhead]

    # Build the set of commands
    # representing the data in 'data_vec'
    # return [set_size, set, flags]
    def __format_data(self, data_vec,data_vec_size=None,data_vec_flags=None):
        # Size verification
        if data_vec_flags!=None:
            assert len(data_vec_flags)==len(data_vec), 'SIZE mismatch between flags and data vectors'

        ## Compute the amount of bytes to proceed
        vlen = data_vec_size
        if data_vec_size==None:
            vlen = len(data_vec)

        # Compute the amount of commands to build
        cmds_amount = ceil(vlen/self.SIZE_CMD_B)

        # Format data as set of 'SIZE_BUS_BYTE' long commands
        dset = bytes([])
        dset_size = 0
        dset_flags = []

        rlen_to_proc = vlen
        i_cmds = 0
        while i_cmds < cmds_amount:
            # check if last instruction
            if i_cmds==(cmds_amount-1):
                # Compute the amount of padding needed
                pad_size = self.SIZE_CMD_B-rlen_to_proc
                
                # Extract data
                index_s= i_cmds*self.SIZE_CMD_B
                offset = rlen_to_proc
                ext_data = bytearray(data_vec[index_s: index_s+offset]) 
                
                # Constant KEEP flags (default, sakura-g compliance)
                com_flags = self.SIZE_CMD_B*[0]
                if data_vec_flags!=None:
                    com_flags = data_vec_flags[index_s : index_s + offset]

                # Extract status
                ext_status = offset*[self.type_process] 

                # Pad if necessary
                if pad_size>0:
                    ext_data = ext_data + bytes(pad_size*[0])
                    com_flags = com_flags + pad_size*[0]
                    ext_status = ext_status + pad_size*['api_ctrl']

                # Reverse the endianess if needed
                if not(self.L_ENDIAN):
                    ext_data.reverse()
                    com_flags.reverse()
                    ext_status.reverse()
                
                # Update states
                dset = dset + bytes(ext_data)
                dset_flags = dset_flags + com_flags
                dset_size = dset_size + 1
                rlen_to_proc = 0
                self.extract_status = self.extract_status + ext_status

            else:
                # Extract data
                index_s= i_cmds*self.SIZE_CMD_B
                offset = self.SIZE_CMD_B
                ext_data = bytearray(data_vec[index_s: index_s+offset]) 
                
                # Constant KEEP flags (default, sakura-g compliance)
                com_flags = self.SIZE_CMD_B*[0]
                if data_vec_flags!=None:
                    com_flags = data_vec_flags[index_s : index_s + offset]

                # Extract status
                ext_status = offset*[self.type_process]

                # Reverse the endianess if neede 
                if not(self.L_ENDIAN):
                    ext_data.reverse()
                    com_flags.reverse()
                    ext_status.reverse()

                # Update states
                dset = dset + bytes(ext_data)
                dset_flags = dset_flags + com_flags
                dset_size = dset_size + 1
                rlen_to_proc = rlen_to_proc - self.SIZE_CMD_B
                self.extract_status = self.extract_status + ext_status

            # Update iterator 
            i_cmds = i_cmds+1

        # Return built set
        return [dset_size,dset,dset_flags]



    # Build the set of commands
    # for an data vector of type 'KEY/NPUB/AD/PT/CT/TAG'
    # return [set_size,set]
    # with the size in term of amount of commands
    def __build_data(self, dtype_s,data_vec,eot,eoi,last,data_vec_size=None,s_nib=0,data_vec_flags=None):    
        ## Compute the amount of bytes to proceed
        dvec_length = data_vec_size
        if data_vec_size==None:
            dvec_length = len(data_vec)

        ## Generic values
        max_bytes_per_seg = self.SEG_MAX_CMDS*self.SIZE_CMD_B

        ## Compute the amount of segments to build
        seg_amount = ceil(dvec_length/max_bytes_per_seg) 

        ## Generate segments of data
        data_inst_set = bytes([])
        data_inst_set_size = 0
        data_inst_flags = []

        ## Default data_vec_flags
        data_vec_f = dvec_length*[0]
        if data_vec_flags!=None:
            assert len(data_vec_flags)==dvec_length, 'SIZE mismath between data and flags'
            data_vec_f = data_vec_flags


        # Remaining size of the data to proceed
        dlen_to_proceed = dvec_length;
        i_seg=0
        while i_seg<seg_amount:
            # Built structure
            [header_set_size,header_set,head_set_flags] = [0,bytes([]),[]]
            [data_set_size,data_set,data_s_f] = [0,bytes([]),[]]

            # Check if last segment
            if i_seg==(seg_amount-1):
                # Build last segment header and data
                [header_set_size,header_set,head_set_flags] = self.__build_header(dtype_s,eot,eoi,last,dlen_to_proceed,sel_nibble=s_nib)
                index_d = i_seg*max_bytes_per_seg
                offset_d = dlen_to_proceed
                [data_set_size,data_set,data_s_f] = self.__format_data(data_vec[index_d:index_d+offset_d],data_vec_size=dlen_to_proceed,data_vec_flags=data_vec_f[index_d:index_d+offset_d])
                dlen_to_proceed = 0
            else:
                # Build last segment header and data
                [header_set_size,header_set,head_set_flags] = self.__build_header(dtype_s,False,False,False,max_bytes_per_seg,sel_nibble=s_nib)
                index_d = i_seg*max_bytes_per_seg
                offset_d = max_bytes_per_seg
                [data_set_size,data_set,data_s_f] = self.__format_data(data_vec[index_d:index_d+offset_d],data_vec_size=max_bytes_per_seg,data_vec_flags=data_vec_f[index_d:index_d+offset_d])
                dlen_to_proceed = dlen_to_proceed-max_bytes_per_seg
            
            # Update states 
            data_inst_set = data_inst_set + header_set + data_set
            data_inst_set_size = data_inst_set_size + header_set_size + data_set_size
            data_inst_flags = data_inst_flags + head_set_flags + data_s_f
            i_seg = i_seg + 1

        # Handle corner case where data is empty: create only an empty segment
        if seg_amount==0:
            [empt_header_set_size,empt_header_set,empt_head_f] = self.__build_header(dtype_s,eot,eoi,last,0)
            data_inst_set_size = empt_header_set_size
            data_inst_set = empt_header_set
            data_inst_flags = empt_head_f

        # Return values
        return [data_inst_set_size, data_inst_set, data_inst_flags]

    # Generate the masked representation
    # take the amount of share
    def __mask_data(self, data_vec,dshare=2,data_vec_flags=None, cst_sharing=False):
        # Compute the length
        ld = len(data_vec)

        # Check size 
        if data_vec_flags!=None:
            assert len(data_vec_flags)==len(data_vec),'SIZE mismatch between flags and data vectors'
            msk_data_flags = dshare * data_vec_flags
        else:
            msk_data_flags = (dshare*ld)*[0]
       
        # Shares
        shares = np.zeros([dshare,ld],dtype=np.int32)
        shares[dshare-1,:] = np.array(list(data_vec),dtype=np.int32)

        # Generate d-1 shares
        if not(cst_sharing):
            shares[:dshare-1,:] = np.random.randint(0,256,[dshare-1,ld],dtype=np.int32)

        # Generate the d_th share
        shares[dshare-1,:] = np.bitwise_xor.reduce(shares)

        # Return
        msk_data = functools.reduce(lambda a,b: bytes(a) + bytes(b),shares.tolist())
        return [msk_data, msk_data_flags]

    # Recombine the shared data 
    def __recombine_data(self, share_vec, share_vec_size=None, dshare=2):
        # Check if we need to compute the length
        lsh = share_vec_size
        if share_vec_size==None:
            lsh=len(share_vec)

        # Length of the original data
        ld = int(lsh/dshare)

        # Reshape shares
        shares = np.reshape(list(share_vec),[dshare,ld])

        # Recombine
        rec_data = np.bitwise_xor.reduce(shares)
    
        # Return
        return bytes(rec_data.tolist())

    def test_data_sharing(self,data,cst_sharing=False):
        md = self.__mask_data(data,cst_sharing=cst_sharing)
        rmd = self.__recombine_data(md[0])
        assert data==rmd

    # Build the set of commands 
    # to perform a 'LOADKEY' instruction
    # Return [set_size, set]
    # with the size in term of the amount of commands
    def build_loadkey(self,k,k_flags=None,cst_sharing=False):
        # Set the current building satus
        if self.CURRENT_BUILD==None:
            self.CURRENT_BUILD = 'loadkey'
            self.reset_extract_status()

        # Check for the minimal size requirements
        lk = len(k)
        assert lk == 16, 'The key should be 16 bytes long in the single-user setting'

        # Generate Instruction
        [inst_set_size, inst_set, inst_flags] = self.__build_inst('loadkey')

        # Flags (sakura-g setup compliance)
        key_flags = lk*[0]
        if k_flags!=None:
            assert len(k_flags)==lk, 'SIZE mismatch between key flags and key data vecs'
            key_flags=k_flags

        # Generate sharing if required
        actual_k = k
        actual_k_flags = key_flags
        if self.DSHARE>1:
            [actual_k,actual_k_flags] = self.__mask_data(k,dshare=self.DSHARE,data_vec_flags=key_flags,cst_sharing=cst_sharing)
           
        # Generate Data 
        [data_set_size, data_set, data_set_f] = self.__build_data('KEY',actual_k,True,False,True,data_vec_flags=actual_k_flags)

        # Return commands
        ldkey_set = inst_set + data_set
        ldkey_set_size = inst_set_size + data_set_size
        ldkey_flags = inst_flags + data_set_f 

        # Reset current building status
        if self.CURRENT_BUILD=='loadkey':
            self.CURRENT_BUILD=None

        return [ldkey_set_size, ldkey_set, ldkey_flags]

    # Build the set of commands 
    # expected for a loadseed instruction
    # Return [set_size,set]
    # with the size in term of amount of commands
    def build_loadseed(self,seed,s_nib=0,seed_flags=None):
        # Set the current building satus
        if self.CURRENT_BUILD==None:
            self.CURRENT_BUILD = 'loadseed'
            self.reset_extract_status()

        # Commands to the send seed instruction
        [inst_seed_set_size, inst_seed_set, inst_flags] = self.__build_inst('ld_seed')

        # Commands related to seed data
        [seed_set_size, seed_set, seed_flags] = self.__build_data('SEED',seed,True,False,True,s_nib=s_nib,data_vec_flags=seed_flags)

        # Return
        load_seed_set = inst_seed_set + seed_set
        load_seed_set_size = inst_seed_set_size + seed_set_size
        load_seed_flags = inst_flags + seed_flags

        # Reset building status
        if self.CURRENT_BUILD=='loadseed':
            self.CURRENT_BUILD = None

        return [load_seed_set_size,load_seed_set,load_seed_flags]


    # Build the set of commands 
    # to perform a 'ENCRYPT' instruction
    # Return [set_size, set]
    # with the size in term of the amount of commands
    def build_encrypt(self,ad,m,n,s0=None,s1=None,s2=None,k=None,kf=None,s0f=None,s1f=None,s2f=None,adf=None,mf=None,nf=None,cst_sharing=False):
        # Set the current building satus
        if self.CURRENT_BUILD==None:
            self.CURRENT_BUILD = 'encrypt'
            self.reset_extract_status()
            
        # Check for the size requirements
        ln = len(n)
        assert  ln == 16, 'The nonce should be 16 bytes long'

        ## Build commands to encrypt
        # Key related commands 
        key_set_size = 0
        key_set = b''
        key_flags = []
        if k!=None:
            [key_set_size,key_set,key_flags] = self.build_loadkey(k,k_flags=kf,cst_sharing=cst_sharing)

        # Seed0 related commands
        s0_set_size = 0
        s0_set = b''
        s0_flags = []
        if s0!=None:
            [s0_set_size,s0_set,s0_flags] = self.build_loadseed(s0,s_nib=0,seed_flags=s0f)

        # Seed1 related commands
        s1_set_size = 0
        s1_set = b''
        s1_flags = []
        if s1!=None:
            [s1_set_size,s1_set,s1_flags] = self.build_loadseed(s1,s_nib=1,seed_flags=s1f)
    
        # Seed2 related commands
        s2_set_size = 0
        s2_set = b''
        s2_flags = []
        if s1!=None:
            [s2_set_size,s2_set,s2_flags] = self.build_loadseed(s2,s_nib=2,seed_flags=s2f)

        # Commands for the encrypt insruction
        [inst_set_size, inst_set, inst_flags] = self.__build_inst('encrypt')

        # Commands to send the nonce
        [nonce_set_size,nonce_set,nonce_flags] = self.__build_data('NPUB',n,True,False,False,data_vec_flags=nf)

        # Commands to send the associatd data
        [ad_set_size,ad_set,ad_flags] = self.__build_data('AD',ad,True,False,False,data_vec_flags=adf)

        # Commands to send the plaintext
        [pt_set_size,pt_set,pt_flags] = self.__build_data('PT',m,True,False,True,data_vec_flags=mf)

        # Return 
        encrypt_set = key_set + s0_set + s1_set + s2_set + inst_set + nonce_set + ad_set + pt_set
        encrypt_set_size = key_set_size + s0_set_size + s1_set_size + s2_set_size + inst_set_size + nonce_set_size + ad_set_size + pt_set_size
        encrypt_flags = key_flags + s0_flags + s1_flags + s2_flags + inst_flags + nonce_flags + ad_flags + pt_flags

        # Reset building status
        if self.CURRENT_BUILD=='encrypt':
            self.CURRENT_BUILD = None

        return [encrypt_set_size,encrypt_set,encrypt_flags]

    # Build the set of commands 
    # to perform a 'DECRYPT' isntruction
    # Return [set_size, set]
    # with the size in term of the amount of commands.
    # The value of the tag is extracted from the ciphertext (i.e., the 16 last bytes)
    def build_decrypt(self,ad,c,n,s0=None,s1=None,s2=None,k=None,kf=None,s0f=None,s1f=None,s2f=None,adf=None,cf=None,nf=None,cst_sharing=False):
        # Set the current building satus
        if self.CURRENT_BUILD==None:
            self.CURRENT_BUILD = 'decrypt'
            self.reset_extract_status()

        # Check for the size requirements
        ln = len(n)
        lc = len(c)
        assert ln == 16, 'The nonce should be 16 bytes long'
        assert lc >= 16, 'The ciphertext provided should be at least 16 bytes long (the TAG length)' 

        # Flags (sakura-g setup compliance)
        c_flags = lc*[0]
        if cf!=None:
            assert len(cf)==lc, 'SIZE mismatch between data and flags'
            c_flags = cf

        # Extract ciphertext and tag values
        lct = lc-16
        tag = c[lct:]
        ct = []
        if lct>0:
            ct = c[0:lct]

        ## Build commands to encrypt
        # Key related commands 
        key_set_size = 0
        key_set = b''
        key_flags = []
        if k!=None:
            [key_set_size,key_set,key_flags] = self.build_loadkey(k,k_flags=kf,cst_sharing=cst_sharing)

        # Seed0 related commands
        s0_set_size = 0
        s0_set = b''
        s0_flags = []
        if s0!=None:
            [s0_set_size,s0_set,s0_flags] = self.build_loadseed(s0,s_nib=0,seed_flags=s0f)

        # Seed1 related commands
        s1_set_size = 0
        s1_set = b''
        s1_flags = []
        if s1!=None:
            [s1_set_size,s1_set,s1_flags] = self.build_loadseed(s1,s_nib=1,seed_flags=s1f)
    
        # Seed2 related commands
        s2_set_size = 0
        s2_set = b''
        s2_flags = []
        if s1!=None:
            [s2_set_size,s2_set,s2_flags] = self.build_loadseed(s2,s_nib=2,seed_flags=s2f)


        ## Build commands to decrypt
        # Commands for the decrypt insruction
        [inst_set_size, inst_set, inst_flags] = self.__build_inst('decrypt')

        # Commands to send the nonce
        [nonce_set_size,nonce_set, nonce_flags] = self.__build_data('NPUB',n,True,False,False,data_vec_flags=nf)

        # Commands to send the associated data
        [ad_set_size,ad_set, ad_flags] = self.__build_data('AD',ad,True,False,False,data_vec_flags=adf)

        # Commands to send the plaintext
        [ct_set_size,ct_set, ct_flags] = self.__build_data('CT',ct,True,False,False,data_vec_flags=c_flags[0:lct])

        # Commands to send the TAG
        [tag_set_size, tag_set, tag_flags] = self.__build_data('TAG',tag,True,False,True,data_vec_flags=c_flags[lct:])

        # Return 
        decrypt_set = key_set + s0_set + s1_set + s2_set + inst_set + nonce_set + ad_set + ct_set + tag_set
        decrypt_set_size = key_set_size + s0_set_size + s1_set_size + s2_set_size + inst_set_size + nonce_set_size + ad_set_size + ct_set_size + tag_set_size
        decrypt_flags = key_flags + s0_flags + s1_flags + s2_flags + inst_flags + nonce_flags + ad_flags + ct_flags + tag_flags

        # Reset building status
        if self.CURRENT_BUILD=='decrypt':
            self.CURRENT_BUILD = None

        return [decrypt_set_size,decrypt_set,decrypt_flags]

    
    # Build the set of commands
    # expected from an encryption process 
    # Return [set_size,set]
    # with the size in term of amount of commands
    def build_res_encrypt(self,c,s0=None,s1=None,s2=None,k=None):
        # Check for the size requirement
        lc = len(c)
        assert lc >= 16, 'The ciphertext provided should be at least 16 bytes long (the TAG length)'

        # Extract ciphertext and tag values
        lct = lc-16
        tag = c[lct:]
        ct = []
        if lct>0:
            ct = c[0:lct]

        # Key related commands 
        key_set_size = 0
        key_set = b''
        if k!=None:
            [key_set_size,key_set,_] = self.__build_inst('status_success')

        # Seed0 related commands
        s0_set_size = 0
        s0_set = b''
        if s0!=None:
            [s0_set_size,s0_set,_] = self.__build_inst('status_success')

        # Seed1 related commands
        s1_set_size = 0
        s1_set = b''
        if s1!=None:
            [s1_set_size,s1_set,_] = self.__build_inst('status_success')
    
        # Seed2 related commands
        s2_set_size = 0
        s2_set = b''
        if s1!=None:
            [s2_set_size,s2_set,_] = self.__build_inst('status_success')


        # Commands related to the ciphertext
        [ct_set_size,ct_set,_] = self.__build_data('CT',ct,True,False,False)

        # Commands related to the TAG
        [tag_set_size, tag_set,_] = self.__build_data('TAG',tag,True,False,True)

        # Commands related to the status
        [status_set_size, status_set,_] = self.__build_inst('status_success')

        # Return
        res_encrypt_set = key_set + s0_set + s1_set + s2_set + ct_set + tag_set + status_set
        res_encrypt_set_size = key_set_size + s0_set_size + s1_set_size + s2_set_size + ct_set_size + tag_set_size + status_set_size

        return [res_encrypt_set_size, res_encrypt_set, _]

    # Build the set of commands
    # expected from an encryption process 
    # Return [set_size,set]
    # with the size in term of amount of commands
    def build_res_decrypt(self,m,s0=None,s1=None,s2=None,k=None):
        # Key related commands 
        key_set_size = 0
        key_set = b''
        if k!=None:
            [key_set_size,key_set,_] = self.__build_inst('status_success')

        # Seed0 related commands
        s0_set_size = 0
        s0_set = b''
        if s0!=None:
            [s0_set_size,s0_set,_] = self.__build_inst('status_success')

        # Seed1 related commands
        s1_set_size = 0
        s1_set = b''
        if s1!=None:
            [s1_set_size,s1_set,_] = self.__build_inst('status_success')
    
        # Seed2 related commands
        s2_set_size = 0
        s2_set = b''
        if s1!=None:
            [s2_set_size,s2_set,_] = self.__build_inst('status_success')

        # Commands to send the plaintext
        [pt_set_size, pt_set,_] = self.__build_data('PT',m,True,False,True)

        # Commands related to the status
        [status_set_size, status_set,_] = self.__build_inst('status_success')

        # Return
        res_decrypt_set = key_set + s0_set + s1_set + s2_set + pt_set + status_set
        res_decrypt_set_size = key_set_size + s0_set_size + s1_set_size + s2_set_size + pt_set_size + status_set_size

        return [res_decrypt_set_size, res_decrypt_set, _]

    def __extract_ram_byte(self,byte,index):
        ram_byte_type = self.extract_status[index]
        if ram_byte_type == 'SEED0':
            self.extract_s0.append(byte)
        elif ram_byte_type == 'SEED1':
            self.extract_s1.append(byte)
        elif ram_byte_type == 'SEED2':
            self.extract_s2.append(byte)
        elif ram_byte_type == 'KEY':
            self.extract_key.append(byte)
        elif ram_byte_type == 'NPUB':
            self.extract_n.append(byte)
        elif ram_byte_type == 'AD':
            self.extract_ad.append(byte)
        elif ram_byte_type == 'PT':
            self.extract_m.append(byte)
        elif ram_byte_type == 'CT':
            self.extract_c.append(byte)
        elif ram_byte_type == 'TAG':
            self.extract_tag.append(byte)

    def __adapt_ext_data_endianess(self,data_vec):
        # Amount of bytes
        ldv = len(data_vec)

        # Pad data
        padding_size = ldv % (self.SIZE_CMD_B)
        if padding_size>0:
            data_vec = data_vec + padding_size*[0]

        # Amount of commands
        ldv_cmd = int((ldv+padding_size)/self.SIZE_CMD_B)

        # Offset
        off = self.SIZE_CMD_B

        # Correct endiannes
        for c in range(ldv_cmd):
            cmd_ext = data_vec[off*c:off*c+off]
            cmd_ext.reverse()
            data_vec[off*c:off*c+off] = cmd_ext

        # Only keep the original amount of byte
        data_vec = data_vec[0:ldv]

    def extract_ram(self,ram):
        # Reset extracted values
        self.reset_extract_values()

        # Length ram
        lram = len(ram)
        assert lram == len(self.extract_status), 'SIZE mismatch between given ram and ram model'
        
        # Extract data from ram
        for i,byte_ram in enumerate(ram):
            self.__extract_ram_byte(byte_ram,i)
   
        # Adapt endiannes if needed
        if not(self.L_ENDIAN):
            self.__adapt_ext_data_endianess(self.extract_s0)
            self.__adapt_ext_data_endianess(self.extract_s1)
            self.__adapt_ext_data_endianess(self.extract_s2)
            self.__adapt_ext_data_endianess(self.extract_key)
            self.__adapt_ext_data_endianess(self.extract_ad)
            self.__adapt_ext_data_endianess(self.extract_n)
            self.__adapt_ext_data_endianess(self.extract_m)
            self.__adapt_ext_data_endianess(self.extract_c)
            self.__adapt_ext_data_endianess(self.extract_tag)

        if self.DSHARE>1:
            self.extract_rec_key = list(self.__recombine_data(self.extract_key,
                dshare=self.DSHARE))
        else:
            self.extract_rec_key = self.extract_key
