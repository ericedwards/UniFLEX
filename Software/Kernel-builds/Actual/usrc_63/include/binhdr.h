          pag** Binary File Header** Each executable binary file must have the following* header associated with it.** struct binhdr          base    0bhhdr     rmb     1          header byte (BNHEAD)bhdes     rmb     1          descriptor byte * see below *bhtxt     rmb     2          size of text segmentbhdat     rmb     2          size of initialized databhbss     rmb     2          size of uninitialized databhrls     rmb     2          size of relocation infobhxfr     rmb     2          transfer addressbhstk     rmb     2          initial stack 9��2��49���96�9���7�:0�62�9��2��41���96�1�����:9�9��2��49�996�9�0�2�1<�2���49�796�14�0�<�9��4��7:��2���$")��2���9��2�7�14�0�<�42��2���'$"��2���14�0�<�42��2�1<�2���22���4�:7�14�9���$")'�2�����92��7�6<�:2�:�$" �2�����0�9��:�2�34�2��$"'&�2�����77�72��6����<�:���7�2��� in fact bnhdr+bhdes form an entity, named info_flags** EXECUTABLE   binary 0x02xx* RELOCATABLE  binary 0x03xx* NO_TEXT      binary 0xxx10* RD_ONLY_TEXT binary 0xxx11* ABSOLUTE     binary 0xxx12* COMMON       binary 0xxx18** other formats** ORIG_BASIC          0x8A00* STAN_PASCAL         0x8B00* SYS_PASCAL          0x8C00* CUR_BASIC           0x9A00*** Absolute file format** Absolute files contain records which look* like the following:*          base    0absct     rmb     2          record size in bytes (data only)absad     rmb     2          load address of data recordABHDSZ    equ     *