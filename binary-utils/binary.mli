type bit

type bin = bit list

val plus : bit list -> bit list -> bit list

val twos_complement : bit list -> bit list

val bin_of_unsigned : int -> bit list

val signed_bin_of_int : int -> bit list

val string_of_bin : bin -> string

val int_of_bin : bit list -> int

val leb128_of_int : int -> int list

val to_uint32 : int -> int list
