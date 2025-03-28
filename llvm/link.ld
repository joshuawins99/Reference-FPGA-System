MEMORY {
    zp : ORIGIN = __rc31 + 1, LENGTH = 0x100 - (__rc31 + 1)
    ram : ORIGIN = 0x0000, LENGTH = 0x2eff
    user_ram (rw) : ORIGIN = 0x200, LENGTH = 0x2cff
}

REGION_ALIAS("c_readonly", user_ram)
REGION_ALIAS("c_writeable", user_ram)


SECTIONS { INCLUDE c.ld }

__rc0 = 0x00;
INCLUDE imag-regs.ld
ASSERT(__rc0 == 0x00, "Inconsistent zero page map.")
ASSERT(__rc31 == 0x1f, "Inconsistent zero page map.")

__stack = 0x2eff;

OUTPUT_FORMAT { FULL(user_ram) SHORT(_start) }
