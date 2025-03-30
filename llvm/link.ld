MEMORY {
    zp : ORIGIN = 0x0000, LENGTH = 0x0100
    ram : ORIGIN = 0x0000, LENGTH = 0x2fff
    user_ram (rw) : ORIGIN = 0x0200, LENGTH = 0x2eff
}

REGION_ALIAS("c_readonly", user_ram)
REGION_ALIAS("c_writeable", user_ram)


SECTIONS { INCLUDE c.ld }

__rc0 = 0x00;
INCLUDE imag-regs.ld
ASSERT(__rc0 == 0x00, "Inconsistent zero page map.")
ASSERT(__rc31 < 0x0100, "Inconsistent zero page map.")

__stack = 0x2fff;

OUTPUT_FORMAT { FULL(user_ram) SHORT(_start) }
