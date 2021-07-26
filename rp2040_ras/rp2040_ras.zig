pub fn Register(comptime R: type) type {
    return RegisterRW(R, R);
}

pub fn RegisterRW(comptime Read: type, comptime Write: type) type {
    return struct {
        raw_ptr: *volatile u32,

        const Self = @This();

        pub fn init(address: usize) Self {
            return Self{ .raw_ptr = @intToPtr(*volatile u32, address) };
        }

        pub fn initRange(address: usize, comptime dim_increment: usize, comptime num_registers: usize) [num_registers]Self {
            var registers: [num_registers]Self = undefined;
            var i: usize = 0;
            while (i < num_registers) : (i += 1) {
                registers[i] = Self.init(address + (i * dim_increment));
            }
            return registers;
        }

        pub fn read(self: Self) Read {
            return @bitCast(Read, self.raw_ptr.*);
        }

        pub fn write(self: Self, value: Write) void {
            var temp = value;
            self.raw_ptr.* = @ptrCast(*u32, @alignCast(4, &temp)).*;
        }

        pub fn modify(self: Self, new_value: anytype) void {
            if (Read != Write) {
                @compileError("Can't modify because read and write types for this register aren't the same.");
            }
            var old_value = self.read();
            const info = @typeInfo(@TypeOf(new_value));
            inline for (info.Struct.fields) |field| {
                @field(old_value, field.name) = @field(new_value, field.name);
            }
            self.write(old_value);
        }

        pub fn read_raw(self: Self) u32 {
            return self.raw_ptr.*;
        }

        pub fn write_raw(self: Self, value: u32) void {
            self.raw_ptr.* = value;
        }

        pub fn default_read_value(self: Self) Read {
            return Read{};
        }

        pub fn default_write_value(self: Self) Write {
            return Write{};
        }
    };
}

pub const device_name = "RP2040";
pub const device_revision = "0.1";
pub const device_description = "unknown";

pub const cpu = struct {
    pub const name = "CM0PLUS";
    pub const revision = "r0p1";
    pub const endian = "little";
    pub const mpu_present = true;
    pub const fpu_present = true;
    pub const vendor_systick_config = false;
    pub const nvic_prio_bits = 2;
};

/// QSPI flash execute-in-place block
pub const XIP_CTRL = struct {

const base_address = 0x14000000;
/// STREAM_FIFO
const STREAM_FIFO_val = packed struct {
STREAM_FIFO_0: u8 = 0,
STREAM_FIFO_1: u8 = 0,
STREAM_FIFO_2: u8 = 0,
STREAM_FIFO_3: u8 = 0,
};
/// FIFO stream data\n
pub const STREAM_FIFO = Register(STREAM_FIFO_val).init(base_address + 0x1c);

/// STREAM_CTR
const STREAM_CTR_val = packed struct {
/// STREAM_CTR [0:21]
/// Write a nonzero value to start a streaming read. This will then\n
STREAM_CTR: u22 = 0,
/// unused [22:31]
_unused22: u2 = 0,
_unused24: u8 = 0,
};
/// FIFO stream control
pub const STREAM_CTR = Register(STREAM_CTR_val).init(base_address + 0x18);

/// STREAM_ADDR
const STREAM_ADDR_val = packed struct {
/// unused [0:1]
_unused0: u2 = 0,
/// STREAM_ADDR [2:31]
/// The address of the next word to be streamed from flash to the streaming FIFO.\n
STREAM_ADDR: u30 = 0,
};
/// FIFO stream address
pub const STREAM_ADDR = Register(STREAM_ADDR_val).init(base_address + 0x14);

/// CTR_ACC
const CTR_ACC_val = packed struct {
CTR_ACC_0: u8 = 0,
CTR_ACC_1: u8 = 0,
CTR_ACC_2: u8 = 0,
CTR_ACC_3: u8 = 0,
};
/// Cache Access counter\n
pub const CTR_ACC = Register(CTR_ACC_val).init(base_address + 0x10);

/// CTR_HIT
const CTR_HIT_val = packed struct {
CTR_HIT_0: u8 = 0,
CTR_HIT_1: u8 = 0,
CTR_HIT_2: u8 = 0,
CTR_HIT_3: u8 = 0,
};
/// Cache Hit counter\n
pub const CTR_HIT = Register(CTR_HIT_val).init(base_address + 0xc);

/// STAT
const STAT_val = packed struct {
/// FLUSH_READY [0:0]
/// Reads as 0 while a cache flush is in progress, and 1 otherwise.\n
FLUSH_READY: u1 = 0,
/// FIFO_EMPTY [1:1]
/// When 1, indicates the XIP streaming FIFO is completely empty.
FIFO_EMPTY: u1 = 1,
/// FIFO_FULL [2:2]
/// When 1, indicates the XIP streaming FIFO is completely full.\n
FIFO_FULL: u1 = 0,
/// unused [3:31]
_unused3: u5 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Cache Status
pub const STAT = Register(STAT_val).init(base_address + 0x8);

/// FLUSH
const FLUSH_val = packed struct {
/// FLUSH [0:0]
/// Write 1 to flush the cache. This clears the tag memory, but\n
FLUSH: u1 = 0,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Cache Flush control
pub const FLUSH = Register(FLUSH_val).init(base_address + 0x4);

/// CTRL
const CTRL_val = packed struct {
/// EN [0:0]
/// When 1, enable the cache. When the cache is disabled, all XIP accesses\n
EN: u1 = 1,
/// ERR_BADWRITE [1:1]
/// When 1, writes to any alias other than 0x0 (caching, allocating)\n
ERR_BADWRITE: u1 = 1,
/// unused [2:2]
_unused2: u1 = 0,
/// POWER_DOWN [3:3]
/// When 1, the cache memories are powered down. They retain state,\n
POWER_DOWN: u1 = 0,
/// unused [4:31]
_unused4: u4 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Cache control
pub const CTRL = Register(CTRL_val).init(base_address + 0x0);
};

/// DW_apb_ssi has the following features:\n
pub const XIP_SSI = struct {

const base_address = 0x18000000;
/// TXD_DRIVE_EDGE
const TXD_DRIVE_EDGE_val = packed struct {
/// TDE [0:7]
/// TXD drive edge
TDE: u8 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// TX drive edge
pub const TXD_DRIVE_EDGE = Register(TXD_DRIVE_EDGE_val).init(base_address + 0xf8);

/// SPI_CTRLR0
const SPI_CTRLR0_val = packed struct {
/// TRANS_TYPE [0:1]
/// Address and instruction transfer format
TRANS_TYPE: u2 = 0,
/// ADDR_L [2:5]
/// Address length (0b-60b in 4b increments)
ADDR_L: u4 = 0,
/// unused [6:7]
_unused6: u2 = 0,
/// INST_L [8:9]
/// Instruction length (0/4/8/16b)
INST_L: u2 = 0,
/// unused [10:10]
_unused10: u1 = 0,
/// WAIT_CYCLES [11:15]
/// Wait cycles between control frame transmit and data reception (in SCLK cycles)
WAIT_CYCLES: u5 = 0,
/// SPI_DDR_EN [16:16]
/// SPI DDR transfer enable
SPI_DDR_EN: u1 = 0,
/// INST_DDR_EN [17:17]
/// Instruction DDR transfer enable
INST_DDR_EN: u1 = 0,
/// SPI_RXDS_EN [18:18]
/// Read data strobe enable
SPI_RXDS_EN: u1 = 0,
/// unused [19:23]
_unused19: u5 = 0,
/// XIP_CMD [24:31]
/// SPI Command to send in XIP mode (INST_L = 8-bit) or to append to Address (INST_L = 0-bit)
XIP_CMD: u8 = 3,
};
/// SPI control
pub const SPI_CTRLR0 = Register(SPI_CTRLR0_val).init(base_address + 0xf4);

/// RX_SAMPLE_DLY
const RX_SAMPLE_DLY_val = packed struct {
/// RSD [0:7]
/// RXD sample delay (in SCLK cycles)
RSD: u8 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// RX sample delay
pub const RX_SAMPLE_DLY = Register(RX_SAMPLE_DLY_val).init(base_address + 0xf0);

/// DR0
const DR0_val = packed struct {
/// DR [0:31]
/// First data register of 36
DR: u32 = 0,
};
/// Data Register 0 (of 36)
pub const DR0 = Register(DR0_val).init(base_address + 0x60);

/// SSI_VERSION_ID
const SSI_VERSION_ID_val = packed struct {
/// SSI_COMP_VERSION [0:31]
/// SNPS component version (format X.YY)
SSI_COMP_VERSION: u32 = 875573546,
};
/// Version ID
pub const SSI_VERSION_ID = Register(SSI_VERSION_ID_val).init(base_address + 0x5c);

/// IDR
const IDR_val = packed struct {
/// IDCODE [0:31]
/// Peripheral dentification code
IDCODE: u32 = 1364414537,
};
/// Identification register
pub const IDR = Register(IDR_val).init(base_address + 0x58);

/// DMARDLR
const DMARDLR_val = packed struct {
/// DMARDL [0:7]
/// Receive data watermark level (DMARDLR+1)
DMARDL: u8 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// DMA RX data level
pub const DMARDLR = Register(DMARDLR_val).init(base_address + 0x54);

/// DMATDLR
const DMATDLR_val = packed struct {
/// DMATDL [0:7]
/// Transmit data watermark level
DMATDL: u8 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// DMA TX data level
pub const DMATDLR = Register(DMATDLR_val).init(base_address + 0x50);

/// DMACR
const DMACR_val = packed struct {
/// RDMAE [0:0]
/// Receive DMA enable
RDMAE: u1 = 0,
/// TDMAE [1:1]
/// Transmit DMA enable
TDMAE: u1 = 0,
/// unused [2:31]
_unused2: u6 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// DMA control
pub const DMACR = Register(DMACR_val).init(base_address + 0x4c);

/// ICR
const ICR_val = packed struct {
/// ICR [0:0]
/// Clear-on-read all active interrupts
ICR: u1 = 0,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Interrupt clear
pub const ICR = Register(ICR_val).init(base_address + 0x48);

/// MSTICR
const MSTICR_val = packed struct {
/// MSTICR [0:0]
/// Clear-on-read multi-master contention interrupt
MSTICR: u1 = 0,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Multi-master interrupt clear
pub const MSTICR = Register(MSTICR_val).init(base_address + 0x44);

/// RXUICR
const RXUICR_val = packed struct {
/// RXUICR [0:0]
/// Clear-on-read receive FIFO underflow interrupt
RXUICR: u1 = 0,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// RX FIFO underflow interrupt clear
pub const RXUICR = Register(RXUICR_val).init(base_address + 0x40);

/// RXOICR
const RXOICR_val = packed struct {
/// RXOICR [0:0]
/// Clear-on-read receive FIFO overflow interrupt
RXOICR: u1 = 0,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// RX FIFO overflow interrupt clear
pub const RXOICR = Register(RXOICR_val).init(base_address + 0x3c);

/// TXOICR
const TXOICR_val = packed struct {
/// TXOICR [0:0]
/// Clear-on-read transmit FIFO overflow interrupt
TXOICR: u1 = 0,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// TX FIFO overflow interrupt clear
pub const TXOICR = Register(TXOICR_val).init(base_address + 0x38);

/// RISR
const RISR_val = packed struct {
/// TXEIR [0:0]
/// Transmit FIFO empty raw interrupt status
TXEIR: u1 = 0,
/// TXOIR [1:1]
/// Transmit FIFO overflow raw interrupt status
TXOIR: u1 = 0,
/// RXUIR [2:2]
/// Receive FIFO underflow raw interrupt status
RXUIR: u1 = 0,
/// RXOIR [3:3]
/// Receive FIFO overflow raw interrupt status
RXOIR: u1 = 0,
/// RXFIR [4:4]
/// Receive FIFO full raw interrupt status
RXFIR: u1 = 0,
/// MSTIR [5:5]
/// Multi-master contention raw interrupt status
MSTIR: u1 = 0,
/// unused [6:31]
_unused6: u2 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Raw interrupt status
pub const RISR = Register(RISR_val).init(base_address + 0x34);

/// ISR
const ISR_val = packed struct {
/// TXEIS [0:0]
/// Transmit FIFO empty interrupt status
TXEIS: u1 = 0,
/// TXOIS [1:1]
/// Transmit FIFO overflow interrupt status
TXOIS: u1 = 0,
/// RXUIS [2:2]
/// Receive FIFO underflow interrupt status
RXUIS: u1 = 0,
/// RXOIS [3:3]
/// Receive FIFO overflow interrupt status
RXOIS: u1 = 0,
/// RXFIS [4:4]
/// Receive FIFO full interrupt status
RXFIS: u1 = 0,
/// MSTIS [5:5]
/// Multi-master contention interrupt status
MSTIS: u1 = 0,
/// unused [6:31]
_unused6: u2 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Interrupt status
pub const ISR = Register(ISR_val).init(base_address + 0x30);

/// IMR
const IMR_val = packed struct {
/// TXEIM [0:0]
/// Transmit FIFO empty interrupt mask
TXEIM: u1 = 0,
/// TXOIM [1:1]
/// Transmit FIFO overflow interrupt mask
TXOIM: u1 = 0,
/// RXUIM [2:2]
/// Receive FIFO underflow interrupt mask
RXUIM: u1 = 0,
/// RXOIM [3:3]
/// Receive FIFO overflow interrupt mask
RXOIM: u1 = 0,
/// RXFIM [4:4]
/// Receive FIFO full interrupt mask
RXFIM: u1 = 0,
/// MSTIM [5:5]
/// Multi-master contention interrupt mask
MSTIM: u1 = 0,
/// unused [6:31]
_unused6: u2 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Interrupt mask
pub const IMR = Register(IMR_val).init(base_address + 0x2c);

/// SR
const SR_val = packed struct {
/// BUSY [0:0]
/// SSI busy flag
BUSY: u1 = 0,
/// TFNF [1:1]
/// Transmit FIFO not full
TFNF: u1 = 0,
/// TFE [2:2]
/// Transmit FIFO empty
TFE: u1 = 0,
/// RFNE [3:3]
/// Receive FIFO not empty
RFNE: u1 = 0,
/// RFF [4:4]
/// Receive FIFO full
RFF: u1 = 0,
/// TXE [5:5]
/// Transmission error
TXE: u1 = 0,
/// DCOL [6:6]
/// Data collision error
DCOL: u1 = 0,
/// unused [7:31]
_unused7: u1 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Status register
pub const SR = Register(SR_val).init(base_address + 0x28);

/// RXFLR
const RXFLR_val = packed struct {
/// RXTFL [0:7]
/// Receive FIFO level
RXTFL: u8 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// RX FIFO level
pub const RXFLR = Register(RXFLR_val).init(base_address + 0x24);

/// TXFLR
const TXFLR_val = packed struct {
/// TFTFL [0:7]
/// Transmit FIFO level
TFTFL: u8 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// TX FIFO level
pub const TXFLR = Register(TXFLR_val).init(base_address + 0x20);

/// RXFTLR
const RXFTLR_val = packed struct {
/// RFT [0:7]
/// Receive FIFO threshold
RFT: u8 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// RX FIFO threshold level
pub const RXFTLR = Register(RXFTLR_val).init(base_address + 0x1c);

/// TXFTLR
const TXFTLR_val = packed struct {
/// TFT [0:7]
/// Transmit FIFO threshold
TFT: u8 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// TX FIFO threshold level
pub const TXFTLR = Register(TXFTLR_val).init(base_address + 0x18);

/// BAUDR
const BAUDR_val = packed struct {
/// SCKDV [0:15]
/// SSI clock divider
SCKDV: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Baud rate
pub const BAUDR = Register(BAUDR_val).init(base_address + 0x14);

/// SER
const SER_val = packed struct {
/// SER [0:0]
/// For each bit:\n
SER: u1 = 0,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Slave enable
pub const SER = Register(SER_val).init(base_address + 0x10);

/// MWCR
const MWCR_val = packed struct {
/// MWMOD [0:0]
/// Microwire transfer mode
MWMOD: u1 = 0,
/// MDD [1:1]
/// Microwire control
MDD: u1 = 0,
/// MHS [2:2]
/// Microwire handshaking
MHS: u1 = 0,
/// unused [3:31]
_unused3: u5 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Microwire Control
pub const MWCR = Register(MWCR_val).init(base_address + 0xc);

/// SSIENR
const SSIENR_val = packed struct {
/// SSI_EN [0:0]
/// SSI enable
SSI_EN: u1 = 0,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// SSI Enable
pub const SSIENR = Register(SSIENR_val).init(base_address + 0x8);

/// CTRLR1
const CTRLR1_val = packed struct {
/// NDF [0:15]
/// Number of data frames
NDF: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Master Control register 1
pub const CTRLR1 = Register(CTRLR1_val).init(base_address + 0x4);

/// CTRLR0
const CTRLR0_val = packed struct {
/// DFS [0:3]
/// Data frame size
DFS: u4 = 0,
/// FRF [4:5]
/// Frame format
FRF: u2 = 0,
/// SCPH [6:6]
/// Serial clock phase
SCPH: u1 = 0,
/// SCPOL [7:7]
/// Serial clock polarity
SCPOL: u1 = 0,
/// TMOD [8:9]
/// Transfer mode
TMOD: u2 = 0,
/// SLV_OE [10:10]
/// Slave output enable
SLV_OE: u1 = 0,
/// SRL [11:11]
/// Shift register loop (test mode)
SRL: u1 = 0,
/// CFS [12:15]
/// Control frame size\n
CFS: u4 = 0,
/// DFS_32 [16:20]
/// Data frame size in 32b transfer mode\n
DFS_32: u5 = 0,
/// SPI_FRF [21:22]
/// SPI frame format
SPI_FRF: u2 = 0,
/// unused [23:23]
_unused23: u1 = 0,
/// SSTE [24:24]
/// Slave select toggle enable
SSTE: u1 = 0,
/// unused [25:31]
_unused25: u7 = 0,
};
/// Control register 0
pub const CTRLR0 = Register(CTRLR0_val).init(base_address + 0x0);
};

/// No description
pub const SYSINFO = struct {

const base_address = 0x40000000;
/// GITREF_RP2040
const GITREF_RP2040_val = packed struct {
GITREF_RP2040_0: u8 = 0,
GITREF_RP2040_1: u8 = 0,
GITREF_RP2040_2: u8 = 0,
GITREF_RP2040_3: u8 = 0,
};
/// Git hash of the chip source. Used to identify chip version.
pub const GITREF_RP2040 = Register(GITREF_RP2040_val).init(base_address + 0x40);

/// PLATFORM
const PLATFORM_val = packed struct {
/// FPGA [0:0]
/// No description
FPGA: u1 = 0,
/// ASIC [1:1]
/// No description
ASIC: u1 = 0,
/// unused [2:31]
_unused2: u6 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Platform register. Allows software to know what environment it is running in.
pub const PLATFORM = Register(PLATFORM_val).init(base_address + 0x4);

/// CHIP_ID
const CHIP_ID_val = packed struct {
/// MANUFACTURER [0:11]
/// No description
MANUFACTURER: u12 = 0,
/// PART [12:27]
/// No description
PART: u16 = 0,
/// REVISION [28:31]
/// No description
REVISION: u4 = 0,
};
/// JEDEC JEP-106 compliant chip identifier.
pub const CHIP_ID = Register(CHIP_ID_val).init(base_address + 0x0);
};

/// Register block for various chip control signals
pub const SYSCFG = struct {

const base_address = 0x40004000;
/// MEMPOWERDOWN
const MEMPOWERDOWN_val = packed struct {
/// SRAM0 [0:0]
/// No description
SRAM0: u1 = 0,
/// SRAM1 [1:1]
/// No description
SRAM1: u1 = 0,
/// SRAM2 [2:2]
/// No description
SRAM2: u1 = 0,
/// SRAM3 [3:3]
/// No description
SRAM3: u1 = 0,
/// SRAM4 [4:4]
/// No description
SRAM4: u1 = 0,
/// SRAM5 [5:5]
/// No description
SRAM5: u1 = 0,
/// USB [6:6]
/// No description
USB: u1 = 0,
/// ROM [7:7]
/// No description
ROM: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Control power downs to memories. Set high to power down memories.\n
pub const MEMPOWERDOWN = Register(MEMPOWERDOWN_val).init(base_address + 0x18);

/// DBGFORCE
const DBGFORCE_val = packed struct {
/// PROC0_SWDO [0:0]
/// Observe the value of processor 0 SWDIO output.
PROC0_SWDO: u1 = 0,
/// PROC0_SWDI [1:1]
/// Directly drive processor 0 SWDIO input, if PROC0_ATTACH is set
PROC0_SWDI: u1 = 1,
/// PROC0_SWCLK [2:2]
/// Directly drive processor 0 SWCLK, if PROC0_ATTACH is set
PROC0_SWCLK: u1 = 1,
/// PROC0_ATTACH [3:3]
/// Attach processor 0 debug port to syscfg controls, and disconnect it from external SWD pads.
PROC0_ATTACH: u1 = 0,
/// PROC1_SWDO [4:4]
/// Observe the value of processor 1 SWDIO output.
PROC1_SWDO: u1 = 0,
/// PROC1_SWDI [5:5]
/// Directly drive processor 1 SWDIO input, if PROC1_ATTACH is set
PROC1_SWDI: u1 = 1,
/// PROC1_SWCLK [6:6]
/// Directly drive processor 1 SWCLK, if PROC1_ATTACH is set
PROC1_SWCLK: u1 = 1,
/// PROC1_ATTACH [7:7]
/// Attach processor 1 debug port to syscfg controls, and disconnect it from external SWD pads.
PROC1_ATTACH: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Directly control the SWD debug port of either processor
pub const DBGFORCE = Register(DBGFORCE_val).init(base_address + 0x14);

/// PROC_IN_SYNC_BYPASS_HI
const PROC_IN_SYNC_BYPASS_HI_val = packed struct {
/// PROC_IN_SYNC_BYPASS_HI [0:5]
/// No description
PROC_IN_SYNC_BYPASS_HI: u6 = 0,
/// unused [6:31]
_unused6: u2 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// For each bit, if 1, bypass the input synchronizer between that GPIO\n
pub const PROC_IN_SYNC_BYPASS_HI = Register(PROC_IN_SYNC_BYPASS_HI_val).init(base_address + 0x10);

/// PROC_IN_SYNC_BYPASS
const PROC_IN_SYNC_BYPASS_val = packed struct {
/// PROC_IN_SYNC_BYPASS [0:29]
/// No description
PROC_IN_SYNC_BYPASS: u30 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// For each bit, if 1, bypass the input synchronizer between that GPIO\n
pub const PROC_IN_SYNC_BYPASS = Register(PROC_IN_SYNC_BYPASS_val).init(base_address + 0xc);

/// PROC_CONFIG
const PROC_CONFIG_val = packed struct {
/// PROC0_HALTED [0:0]
/// Indication that proc0 has halted
PROC0_HALTED: u1 = 0,
/// PROC1_HALTED [1:1]
/// Indication that proc1 has halted
PROC1_HALTED: u1 = 0,
/// unused [2:23]
_unused2: u6 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
/// PROC0_DAP_INSTID [24:27]
/// Configure proc0 DAP instance ID.\n
PROC0_DAP_INSTID: u4 = 0,
/// PROC1_DAP_INSTID [28:31]
/// Configure proc1 DAP instance ID.\n
PROC1_DAP_INSTID: u4 = 1,
};
/// Configuration for processors
pub const PROC_CONFIG = Register(PROC_CONFIG_val).init(base_address + 0x8);

/// PROC1_NMI_MASK
const PROC1_NMI_MASK_val = packed struct {
PROC1_NMI_MASK_0: u8 = 0,
PROC1_NMI_MASK_1: u8 = 0,
PROC1_NMI_MASK_2: u8 = 0,
PROC1_NMI_MASK_3: u8 = 0,
};
/// Processor core 1 NMI source mask\n
pub const PROC1_NMI_MASK = Register(PROC1_NMI_MASK_val).init(base_address + 0x4);

/// PROC0_NMI_MASK
const PROC0_NMI_MASK_val = packed struct {
PROC0_NMI_MASK_0: u8 = 0,
PROC0_NMI_MASK_1: u8 = 0,
PROC0_NMI_MASK_2: u8 = 0,
PROC0_NMI_MASK_3: u8 = 0,
};
/// Processor core 0 NMI source mask\n
pub const PROC0_NMI_MASK = Register(PROC0_NMI_MASK_val).init(base_address + 0x0);
};

/// No description
pub const CLOCKS = struct {

const base_address = 0x40008000;
/// INTS
const INTS_val = packed struct {
/// CLK_SYS_RESUS [0:0]
/// No description
CLK_SYS_RESUS: u1 = 0,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Interrupt status after masking &amp; forcing
pub const INTS = Register(INTS_val).init(base_address + 0xc4);

/// INTF
const INTF_val = packed struct {
/// CLK_SYS_RESUS [0:0]
/// No description
CLK_SYS_RESUS: u1 = 0,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Interrupt Force
pub const INTF = Register(INTF_val).init(base_address + 0xc0);

/// INTE
const INTE_val = packed struct {
/// CLK_SYS_RESUS [0:0]
/// No description
CLK_SYS_RESUS: u1 = 0,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Interrupt Enable
pub const INTE = Register(INTE_val).init(base_address + 0xbc);

/// INTR
const INTR_val = packed struct {
/// CLK_SYS_RESUS [0:0]
/// No description
CLK_SYS_RESUS: u1 = 0,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Raw Interrupts
pub const INTR = Register(INTR_val).init(base_address + 0xb8);

/// ENABLED1
const ENABLED1_val = packed struct {
/// clk_sys_sram4 [0:0]
/// No description
clk_sys_sram4: u1 = 0,
/// clk_sys_sram5 [1:1]
/// No description
clk_sys_sram5: u1 = 0,
/// clk_sys_syscfg [2:2]
/// No description
clk_sys_syscfg: u1 = 0,
/// clk_sys_sysinfo [3:3]
/// No description
clk_sys_sysinfo: u1 = 0,
/// clk_sys_tbman [4:4]
/// No description
clk_sys_tbman: u1 = 0,
/// clk_sys_timer [5:5]
/// No description
clk_sys_timer: u1 = 0,
/// clk_peri_uart0 [6:6]
/// No description
clk_peri_uart0: u1 = 0,
/// clk_sys_uart0 [7:7]
/// No description
clk_sys_uart0: u1 = 0,
/// clk_peri_uart1 [8:8]
/// No description
clk_peri_uart1: u1 = 0,
/// clk_sys_uart1 [9:9]
/// No description
clk_sys_uart1: u1 = 0,
/// clk_sys_usbctrl [10:10]
/// No description
clk_sys_usbctrl: u1 = 0,
/// clk_usb_usbctrl [11:11]
/// No description
clk_usb_usbctrl: u1 = 0,
/// clk_sys_watchdog [12:12]
/// No description
clk_sys_watchdog: u1 = 0,
/// clk_sys_xip [13:13]
/// No description
clk_sys_xip: u1 = 0,
/// clk_sys_xosc [14:14]
/// No description
clk_sys_xosc: u1 = 0,
/// unused [15:31]
_unused15: u1 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// indicates the state of the clock enable
pub const ENABLED1 = Register(ENABLED1_val).init(base_address + 0xb4);

/// ENABLED0
const ENABLED0_val = packed struct {
/// clk_sys_clocks [0:0]
/// No description
clk_sys_clocks: u1 = 0,
/// clk_adc_adc [1:1]
/// No description
clk_adc_adc: u1 = 0,
/// clk_sys_adc [2:2]
/// No description
clk_sys_adc: u1 = 0,
/// clk_sys_busctrl [3:3]
/// No description
clk_sys_busctrl: u1 = 0,
/// clk_sys_busfabric [4:4]
/// No description
clk_sys_busfabric: u1 = 0,
/// clk_sys_dma [5:5]
/// No description
clk_sys_dma: u1 = 0,
/// clk_sys_i2c0 [6:6]
/// No description
clk_sys_i2c0: u1 = 0,
/// clk_sys_i2c1 [7:7]
/// No description
clk_sys_i2c1: u1 = 0,
/// clk_sys_io [8:8]
/// No description
clk_sys_io: u1 = 0,
/// clk_sys_jtag [9:9]
/// No description
clk_sys_jtag: u1 = 0,
/// clk_sys_vreg_and_chip_reset [10:10]
/// No description
clk_sys_vreg_and_chip_reset: u1 = 0,
/// clk_sys_pads [11:11]
/// No description
clk_sys_pads: u1 = 0,
/// clk_sys_pio0 [12:12]
/// No description
clk_sys_pio0: u1 = 0,
/// clk_sys_pio1 [13:13]
/// No description
clk_sys_pio1: u1 = 0,
/// clk_sys_pll_sys [14:14]
/// No description
clk_sys_pll_sys: u1 = 0,
/// clk_sys_pll_usb [15:15]
/// No description
clk_sys_pll_usb: u1 = 0,
/// clk_sys_psm [16:16]
/// No description
clk_sys_psm: u1 = 0,
/// clk_sys_pwm [17:17]
/// No description
clk_sys_pwm: u1 = 0,
/// clk_sys_resets [18:18]
/// No description
clk_sys_resets: u1 = 0,
/// clk_sys_rom [19:19]
/// No description
clk_sys_rom: u1 = 0,
/// clk_sys_rosc [20:20]
/// No description
clk_sys_rosc: u1 = 0,
/// clk_rtc_rtc [21:21]
/// No description
clk_rtc_rtc: u1 = 0,
/// clk_sys_rtc [22:22]
/// No description
clk_sys_rtc: u1 = 0,
/// clk_sys_sio [23:23]
/// No description
clk_sys_sio: u1 = 0,
/// clk_peri_spi0 [24:24]
/// No description
clk_peri_spi0: u1 = 0,
/// clk_sys_spi0 [25:25]
/// No description
clk_sys_spi0: u1 = 0,
/// clk_peri_spi1 [26:26]
/// No description
clk_peri_spi1: u1 = 0,
/// clk_sys_spi1 [27:27]
/// No description
clk_sys_spi1: u1 = 0,
/// clk_sys_sram0 [28:28]
/// No description
clk_sys_sram0: u1 = 0,
/// clk_sys_sram1 [29:29]
/// No description
clk_sys_sram1: u1 = 0,
/// clk_sys_sram2 [30:30]
/// No description
clk_sys_sram2: u1 = 0,
/// clk_sys_sram3 [31:31]
/// No description
clk_sys_sram3: u1 = 0,
};
/// indicates the state of the clock enable
pub const ENABLED0 = Register(ENABLED0_val).init(base_address + 0xb0);

/// SLEEP_EN1
const SLEEP_EN1_val = packed struct {
/// clk_sys_sram4 [0:0]
/// No description
clk_sys_sram4: u1 = 1,
/// clk_sys_sram5 [1:1]
/// No description
clk_sys_sram5: u1 = 1,
/// clk_sys_syscfg [2:2]
/// No description
clk_sys_syscfg: u1 = 1,
/// clk_sys_sysinfo [3:3]
/// No description
clk_sys_sysinfo: u1 = 1,
/// clk_sys_tbman [4:4]
/// No description
clk_sys_tbman: u1 = 1,
/// clk_sys_timer [5:5]
/// No description
clk_sys_timer: u1 = 1,
/// clk_peri_uart0 [6:6]
/// No description
clk_peri_uart0: u1 = 1,
/// clk_sys_uart0 [7:7]
/// No description
clk_sys_uart0: u1 = 1,
/// clk_peri_uart1 [8:8]
/// No description
clk_peri_uart1: u1 = 1,
/// clk_sys_uart1 [9:9]
/// No description
clk_sys_uart1: u1 = 1,
/// clk_sys_usbctrl [10:10]
/// No description
clk_sys_usbctrl: u1 = 1,
/// clk_usb_usbctrl [11:11]
/// No description
clk_usb_usbctrl: u1 = 1,
/// clk_sys_watchdog [12:12]
/// No description
clk_sys_watchdog: u1 = 1,
/// clk_sys_xip [13:13]
/// No description
clk_sys_xip: u1 = 1,
/// clk_sys_xosc [14:14]
/// No description
clk_sys_xosc: u1 = 1,
/// unused [15:31]
_unused15: u1 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// enable clock in sleep mode
pub const SLEEP_EN1 = Register(SLEEP_EN1_val).init(base_address + 0xac);

/// SLEEP_EN0
const SLEEP_EN0_val = packed struct {
/// clk_sys_clocks [0:0]
/// No description
clk_sys_clocks: u1 = 1,
/// clk_adc_adc [1:1]
/// No description
clk_adc_adc: u1 = 1,
/// clk_sys_adc [2:2]
/// No description
clk_sys_adc: u1 = 1,
/// clk_sys_busctrl [3:3]
/// No description
clk_sys_busctrl: u1 = 1,
/// clk_sys_busfabric [4:4]
/// No description
clk_sys_busfabric: u1 = 1,
/// clk_sys_dma [5:5]
/// No description
clk_sys_dma: u1 = 1,
/// clk_sys_i2c0 [6:6]
/// No description
clk_sys_i2c0: u1 = 1,
/// clk_sys_i2c1 [7:7]
/// No description
clk_sys_i2c1: u1 = 1,
/// clk_sys_io [8:8]
/// No description
clk_sys_io: u1 = 1,
/// clk_sys_jtag [9:9]
/// No description
clk_sys_jtag: u1 = 1,
/// clk_sys_vreg_and_chip_reset [10:10]
/// No description
clk_sys_vreg_and_chip_reset: u1 = 1,
/// clk_sys_pads [11:11]
/// No description
clk_sys_pads: u1 = 1,
/// clk_sys_pio0 [12:12]
/// No description
clk_sys_pio0: u1 = 1,
/// clk_sys_pio1 [13:13]
/// No description
clk_sys_pio1: u1 = 1,
/// clk_sys_pll_sys [14:14]
/// No description
clk_sys_pll_sys: u1 = 1,
/// clk_sys_pll_usb [15:15]
/// No description
clk_sys_pll_usb: u1 = 1,
/// clk_sys_psm [16:16]
/// No description
clk_sys_psm: u1 = 1,
/// clk_sys_pwm [17:17]
/// No description
clk_sys_pwm: u1 = 1,
/// clk_sys_resets [18:18]
/// No description
clk_sys_resets: u1 = 1,
/// clk_sys_rom [19:19]
/// No description
clk_sys_rom: u1 = 1,
/// clk_sys_rosc [20:20]
/// No description
clk_sys_rosc: u1 = 1,
/// clk_rtc_rtc [21:21]
/// No description
clk_rtc_rtc: u1 = 1,
/// clk_sys_rtc [22:22]
/// No description
clk_sys_rtc: u1 = 1,
/// clk_sys_sio [23:23]
/// No description
clk_sys_sio: u1 = 1,
/// clk_peri_spi0 [24:24]
/// No description
clk_peri_spi0: u1 = 1,
/// clk_sys_spi0 [25:25]
/// No description
clk_sys_spi0: u1 = 1,
/// clk_peri_spi1 [26:26]
/// No description
clk_peri_spi1: u1 = 1,
/// clk_sys_spi1 [27:27]
/// No description
clk_sys_spi1: u1 = 1,
/// clk_sys_sram0 [28:28]
/// No description
clk_sys_sram0: u1 = 1,
/// clk_sys_sram1 [29:29]
/// No description
clk_sys_sram1: u1 = 1,
/// clk_sys_sram2 [30:30]
/// No description
clk_sys_sram2: u1 = 1,
/// clk_sys_sram3 [31:31]
/// No description
clk_sys_sram3: u1 = 1,
};
/// enable clock in sleep mode
pub const SLEEP_EN0 = Register(SLEEP_EN0_val).init(base_address + 0xa8);

/// WAKE_EN1
const WAKE_EN1_val = packed struct {
/// clk_sys_sram4 [0:0]
/// No description
clk_sys_sram4: u1 = 1,
/// clk_sys_sram5 [1:1]
/// No description
clk_sys_sram5: u1 = 1,
/// clk_sys_syscfg [2:2]
/// No description
clk_sys_syscfg: u1 = 1,
/// clk_sys_sysinfo [3:3]
/// No description
clk_sys_sysinfo: u1 = 1,
/// clk_sys_tbman [4:4]
/// No description
clk_sys_tbman: u1 = 1,
/// clk_sys_timer [5:5]
/// No description
clk_sys_timer: u1 = 1,
/// clk_peri_uart0 [6:6]
/// No description
clk_peri_uart0: u1 = 1,
/// clk_sys_uart0 [7:7]
/// No description
clk_sys_uart0: u1 = 1,
/// clk_peri_uart1 [8:8]
/// No description
clk_peri_uart1: u1 = 1,
/// clk_sys_uart1 [9:9]
/// No description
clk_sys_uart1: u1 = 1,
/// clk_sys_usbctrl [10:10]
/// No description
clk_sys_usbctrl: u1 = 1,
/// clk_usb_usbctrl [11:11]
/// No description
clk_usb_usbctrl: u1 = 1,
/// clk_sys_watchdog [12:12]
/// No description
clk_sys_watchdog: u1 = 1,
/// clk_sys_xip [13:13]
/// No description
clk_sys_xip: u1 = 1,
/// clk_sys_xosc [14:14]
/// No description
clk_sys_xosc: u1 = 1,
/// unused [15:31]
_unused15: u1 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// enable clock in wake mode
pub const WAKE_EN1 = Register(WAKE_EN1_val).init(base_address + 0xa4);

/// WAKE_EN0
const WAKE_EN0_val = packed struct {
/// clk_sys_clocks [0:0]
/// No description
clk_sys_clocks: u1 = 1,
/// clk_adc_adc [1:1]
/// No description
clk_adc_adc: u1 = 1,
/// clk_sys_adc [2:2]
/// No description
clk_sys_adc: u1 = 1,
/// clk_sys_busctrl [3:3]
/// No description
clk_sys_busctrl: u1 = 1,
/// clk_sys_busfabric [4:4]
/// No description
clk_sys_busfabric: u1 = 1,
/// clk_sys_dma [5:5]
/// No description
clk_sys_dma: u1 = 1,
/// clk_sys_i2c0 [6:6]
/// No description
clk_sys_i2c0: u1 = 1,
/// clk_sys_i2c1 [7:7]
/// No description
clk_sys_i2c1: u1 = 1,
/// clk_sys_io [8:8]
/// No description
clk_sys_io: u1 = 1,
/// clk_sys_jtag [9:9]
/// No description
clk_sys_jtag: u1 = 1,
/// clk_sys_vreg_and_chip_reset [10:10]
/// No description
clk_sys_vreg_and_chip_reset: u1 = 1,
/// clk_sys_pads [11:11]
/// No description
clk_sys_pads: u1 = 1,
/// clk_sys_pio0 [12:12]
/// No description
clk_sys_pio0: u1 = 1,
/// clk_sys_pio1 [13:13]
/// No description
clk_sys_pio1: u1 = 1,
/// clk_sys_pll_sys [14:14]
/// No description
clk_sys_pll_sys: u1 = 1,
/// clk_sys_pll_usb [15:15]
/// No description
clk_sys_pll_usb: u1 = 1,
/// clk_sys_psm [16:16]
/// No description
clk_sys_psm: u1 = 1,
/// clk_sys_pwm [17:17]
/// No description
clk_sys_pwm: u1 = 1,
/// clk_sys_resets [18:18]
/// No description
clk_sys_resets: u1 = 1,
/// clk_sys_rom [19:19]
/// No description
clk_sys_rom: u1 = 1,
/// clk_sys_rosc [20:20]
/// No description
clk_sys_rosc: u1 = 1,
/// clk_rtc_rtc [21:21]
/// No description
clk_rtc_rtc: u1 = 1,
/// clk_sys_rtc [22:22]
/// No description
clk_sys_rtc: u1 = 1,
/// clk_sys_sio [23:23]
/// No description
clk_sys_sio: u1 = 1,
/// clk_peri_spi0 [24:24]
/// No description
clk_peri_spi0: u1 = 1,
/// clk_sys_spi0 [25:25]
/// No description
clk_sys_spi0: u1 = 1,
/// clk_peri_spi1 [26:26]
/// No description
clk_peri_spi1: u1 = 1,
/// clk_sys_spi1 [27:27]
/// No description
clk_sys_spi1: u1 = 1,
/// clk_sys_sram0 [28:28]
/// No description
clk_sys_sram0: u1 = 1,
/// clk_sys_sram1 [29:29]
/// No description
clk_sys_sram1: u1 = 1,
/// clk_sys_sram2 [30:30]
/// No description
clk_sys_sram2: u1 = 1,
/// clk_sys_sram3 [31:31]
/// No description
clk_sys_sram3: u1 = 1,
};
/// enable clock in wake mode
pub const WAKE_EN0 = Register(WAKE_EN0_val).init(base_address + 0xa0);

/// FC0_RESULT
const FC0_RESULT_val = packed struct {
/// FRAC [0:4]
/// No description
FRAC: u5 = 0,
/// KHZ [5:29]
/// No description
KHZ: u25 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// Result of frequency measurement, only valid when status_done=1
pub const FC0_RESULT = Register(FC0_RESULT_val).init(base_address + 0x9c);

/// FC0_STATUS
const FC0_STATUS_val = packed struct {
/// PASS [0:0]
/// Test passed
PASS: u1 = 0,
/// unused [1:3]
_unused1: u3 = 0,
/// DONE [4:4]
/// Test complete
DONE: u1 = 0,
/// unused [5:7]
_unused5: u3 = 0,
/// RUNNING [8:8]
/// Test running
RUNNING: u1 = 0,
/// unused [9:11]
_unused9: u3 = 0,
/// WAITING [12:12]
/// Waiting for test clock to start
WAITING: u1 = 0,
/// unused [13:15]
_unused13: u3 = 0,
/// FAIL [16:16]
/// Test failed
FAIL: u1 = 0,
/// unused [17:19]
_unused17: u3 = 0,
/// SLOW [20:20]
/// Test clock slower than expected, only valid when status_done=1
SLOW: u1 = 0,
/// unused [21:23]
_unused21: u3 = 0,
/// FAST [24:24]
/// Test clock faster than expected, only valid when status_done=1
FAST: u1 = 0,
/// unused [25:27]
_unused25: u3 = 0,
/// DIED [28:28]
/// Test clock stopped during test
DIED: u1 = 0,
/// unused [29:31]
_unused29: u3 = 0,
};
/// Frequency counter status
pub const FC0_STATUS = Register(FC0_STATUS_val).init(base_address + 0x98);

/// FC0_SRC
const FC0_SRC_val = packed struct {
/// FC0_SRC [0:7]
/// No description
FC0_SRC: u8 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Clock sent to frequency counter, set to 0 when not required\n
pub const FC0_SRC = Register(FC0_SRC_val).init(base_address + 0x94);

/// FC0_INTERVAL
const FC0_INTERVAL_val = packed struct {
/// FC0_INTERVAL [0:3]
/// No description
FC0_INTERVAL: u4 = 8,
/// unused [4:31]
_unused4: u4 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// The test interval is 0.98us * 2**interval, but let's call it 1us * 2**interval\n
pub const FC0_INTERVAL = Register(FC0_INTERVAL_val).init(base_address + 0x90);

/// FC0_DELAY
const FC0_DELAY_val = packed struct {
/// FC0_DELAY [0:2]
/// No description
FC0_DELAY: u3 = 1,
/// unused [3:31]
_unused3: u5 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Delays the start of frequency counting to allow the mux to settle\n
pub const FC0_DELAY = Register(FC0_DELAY_val).init(base_address + 0x8c);

/// FC0_MAX_KHZ
const FC0_MAX_KHZ_val = packed struct {
/// FC0_MAX_KHZ [0:24]
/// No description
FC0_MAX_KHZ: u25 = 33554431,
/// unused [25:31]
_unused25: u7 = 0,
};
/// Maximum pass frequency in kHz. This is optional. Set to 0x1ffffff if you are not using the pass/fail flags
pub const FC0_MAX_KHZ = Register(FC0_MAX_KHZ_val).init(base_address + 0x88);

/// FC0_MIN_KHZ
const FC0_MIN_KHZ_val = packed struct {
/// FC0_MIN_KHZ [0:24]
/// No description
FC0_MIN_KHZ: u25 = 0,
/// unused [25:31]
_unused25: u7 = 0,
};
/// Minimum pass frequency in kHz. This is optional. Set to 0 if you are not using the pass/fail flags
pub const FC0_MIN_KHZ = Register(FC0_MIN_KHZ_val).init(base_address + 0x84);

/// FC0_REF_KHZ
const FC0_REF_KHZ_val = packed struct {
/// FC0_REF_KHZ [0:19]
/// No description
FC0_REF_KHZ: u20 = 0,
/// unused [20:31]
_unused20: u4 = 0,
_unused24: u8 = 0,
};
/// Reference clock frequency in kHz
pub const FC0_REF_KHZ = Register(FC0_REF_KHZ_val).init(base_address + 0x80);

/// CLK_SYS_RESUS_STATUS
const CLK_SYS_RESUS_STATUS_val = packed struct {
/// RESUSSED [0:0]
/// Clock has been resuscitated, correct the error then send ctrl_clear=1
RESUSSED: u1 = 0,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// No description
pub const CLK_SYS_RESUS_STATUS = Register(CLK_SYS_RESUS_STATUS_val).init(base_address + 0x7c);

/// CLK_SYS_RESUS_CTRL
const CLK_SYS_RESUS_CTRL_val = packed struct {
/// TIMEOUT [0:7]
/// This is expressed as a number of clk_ref cycles\n
TIMEOUT: u8 = 255,
/// ENABLE [8:8]
/// Enable resus
ENABLE: u1 = 0,
/// unused [9:11]
_unused9: u3 = 0,
/// FRCE [12:12]
/// Force a resus, for test purposes only
FRCE: u1 = 0,
/// unused [13:15]
_unused13: u3 = 0,
/// CLEAR [16:16]
/// For clearing the resus after the fault that triggered it has been corrected
CLEAR: u1 = 0,
/// unused [17:31]
_unused17: u7 = 0,
_unused24: u8 = 0,
};
/// No description
pub const CLK_SYS_RESUS_CTRL = Register(CLK_SYS_RESUS_CTRL_val).init(base_address + 0x78);

/// CLK_RTC_SELECTED
const CLK_RTC_SELECTED_val = packed struct {
CLK_RTC_SELECTED_0: u8 = 1,
CLK_RTC_SELECTED_1: u8 = 0,
CLK_RTC_SELECTED_2: u8 = 0,
CLK_RTC_SELECTED_3: u8 = 0,
};
/// Indicates which SRC is currently selected by the glitchless mux (one-hot).\n
pub const CLK_RTC_SELECTED = Register(CLK_RTC_SELECTED_val).init(base_address + 0x74);

/// CLK_RTC_DIV
const CLK_RTC_DIV_val = packed struct {
/// FRAC [0:7]
/// Fractional component of the divisor
FRAC: u8 = 0,
/// INT [8:31]
/// Integer component of the divisor, 0 -&gt; divide by 2^16
INT: u24 = 1,
};
/// Clock divisor, can be changed on-the-fly
pub const CLK_RTC_DIV = Register(CLK_RTC_DIV_val).init(base_address + 0x70);

/// CLK_RTC_CTRL
const CLK_RTC_CTRL_val = packed struct {
/// unused [0:4]
_unused0: u5 = 0,
/// AUXSRC [5:7]
/// Selects the auxiliary clock source, will glitch when switching
AUXSRC: u3 = 0,
/// unused [8:9]
_unused8: u2 = 0,
/// KILL [10:10]
/// Asynchronously kills the clock generator
KILL: u1 = 0,
/// ENABLE [11:11]
/// Starts and stops the clock generator cleanly
ENABLE: u1 = 0,
/// unused [12:15]
_unused12: u4 = 0,
/// PHASE [16:17]
/// This delays the enable signal by up to 3 cycles of the input clock\n
PHASE: u2 = 0,
/// unused [18:19]
_unused18: u2 = 0,
/// NUDGE [20:20]
/// An edge on this signal shifts the phase of the output by 1 cycle of the input clock\n
NUDGE: u1 = 0,
/// unused [21:31]
_unused21: u3 = 0,
_unused24: u8 = 0,
};
/// Clock control, can be changed on-the-fly (except for auxsrc)
pub const CLK_RTC_CTRL = Register(CLK_RTC_CTRL_val).init(base_address + 0x6c);

/// CLK_ADC_SELECTED
const CLK_ADC_SELECTED_val = packed struct {
CLK_ADC_SELECTED_0: u8 = 1,
CLK_ADC_SELECTED_1: u8 = 0,
CLK_ADC_SELECTED_2: u8 = 0,
CLK_ADC_SELECTED_3: u8 = 0,
};
/// Indicates which SRC is currently selected by the glitchless mux (one-hot).\n
pub const CLK_ADC_SELECTED = Register(CLK_ADC_SELECTED_val).init(base_address + 0x68);

/// CLK_ADC_DIV
const CLK_ADC_DIV_val = packed struct {
/// unused [0:7]
_unused0: u8 = 0,
/// INT [8:9]
/// Integer component of the divisor, 0 -&gt; divide by 2^16
INT: u2 = 1,
/// unused [10:31]
_unused10: u6 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Clock divisor, can be changed on-the-fly
pub const CLK_ADC_DIV = Register(CLK_ADC_DIV_val).init(base_address + 0x64);

/// CLK_ADC_CTRL
const CLK_ADC_CTRL_val = packed struct {
/// unused [0:4]
_unused0: u5 = 0,
/// AUXSRC [5:7]
/// Selects the auxiliary clock source, will glitch when switching
AUXSRC: u3 = 0,
/// unused [8:9]
_unused8: u2 = 0,
/// KILL [10:10]
/// Asynchronously kills the clock generator
KILL: u1 = 0,
/// ENABLE [11:11]
/// Starts and stops the clock generator cleanly
ENABLE: u1 = 0,
/// unused [12:15]
_unused12: u4 = 0,
/// PHASE [16:17]
/// This delays the enable signal by up to 3 cycles of the input clock\n
PHASE: u2 = 0,
/// unused [18:19]
_unused18: u2 = 0,
/// NUDGE [20:20]
/// An edge on this signal shifts the phase of the output by 1 cycle of the input clock\n
NUDGE: u1 = 0,
/// unused [21:31]
_unused21: u3 = 0,
_unused24: u8 = 0,
};
/// Clock control, can be changed on-the-fly (except for auxsrc)
pub const CLK_ADC_CTRL = Register(CLK_ADC_CTRL_val).init(base_address + 0x60);

/// CLK_USB_SELECTED
const CLK_USB_SELECTED_val = packed struct {
CLK_USB_SELECTED_0: u8 = 1,
CLK_USB_SELECTED_1: u8 = 0,
CLK_USB_SELECTED_2: u8 = 0,
CLK_USB_SELECTED_3: u8 = 0,
};
/// Indicates which SRC is currently selected by the glitchless mux (one-hot).\n
pub const CLK_USB_SELECTED = Register(CLK_USB_SELECTED_val).init(base_address + 0x5c);

/// CLK_USB_DIV
const CLK_USB_DIV_val = packed struct {
/// unused [0:7]
_unused0: u8 = 0,
/// INT [8:9]
/// Integer component of the divisor, 0 -&gt; divide by 2^16
INT: u2 = 1,
/// unused [10:31]
_unused10: u6 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Clock divisor, can be changed on-the-fly
pub const CLK_USB_DIV = Register(CLK_USB_DIV_val).init(base_address + 0x58);

/// CLK_USB_CTRL
const CLK_USB_CTRL_val = packed struct {
/// unused [0:4]
_unused0: u5 = 0,
/// AUXSRC [5:7]
/// Selects the auxiliary clock source, will glitch when switching
AUXSRC: u3 = 0,
/// unused [8:9]
_unused8: u2 = 0,
/// KILL [10:10]
/// Asynchronously kills the clock generator
KILL: u1 = 0,
/// ENABLE [11:11]
/// Starts and stops the clock generator cleanly
ENABLE: u1 = 0,
/// unused [12:15]
_unused12: u4 = 0,
/// PHASE [16:17]
/// This delays the enable signal by up to 3 cycles of the input clock\n
PHASE: u2 = 0,
/// unused [18:19]
_unused18: u2 = 0,
/// NUDGE [20:20]
/// An edge on this signal shifts the phase of the output by 1 cycle of the input clock\n
NUDGE: u1 = 0,
/// unused [21:31]
_unused21: u3 = 0,
_unused24: u8 = 0,
};
/// Clock control, can be changed on-the-fly (except for auxsrc)
pub const CLK_USB_CTRL = Register(CLK_USB_CTRL_val).init(base_address + 0x54);

/// CLK_PERI_SELECTED
const CLK_PERI_SELECTED_val = packed struct {
CLK_PERI_SELECTED_0: u8 = 1,
CLK_PERI_SELECTED_1: u8 = 0,
CLK_PERI_SELECTED_2: u8 = 0,
CLK_PERI_SELECTED_3: u8 = 0,
};
/// Indicates which SRC is currently selected by the glitchless mux (one-hot).\n
pub const CLK_PERI_SELECTED = Register(CLK_PERI_SELECTED_val).init(base_address + 0x50);

/// CLK_PERI_CTRL
const CLK_PERI_CTRL_val = packed struct {
/// unused [0:4]
_unused0: u5 = 0,
/// AUXSRC [5:7]
/// Selects the auxiliary clock source, will glitch when switching
AUXSRC: u3 = 0,
/// unused [8:9]
_unused8: u2 = 0,
/// KILL [10:10]
/// Asynchronously kills the clock generator
KILL: u1 = 0,
/// ENABLE [11:11]
/// Starts and stops the clock generator cleanly
ENABLE: u1 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Clock control, can be changed on-the-fly (except for auxsrc)
pub const CLK_PERI_CTRL = Register(CLK_PERI_CTRL_val).init(base_address + 0x48);

/// CLK_SYS_SELECTED
const CLK_SYS_SELECTED_val = packed struct {
CLK_SYS_SELECTED_0: u8 = 1,
CLK_SYS_SELECTED_1: u8 = 0,
CLK_SYS_SELECTED_2: u8 = 0,
CLK_SYS_SELECTED_3: u8 = 0,
};
/// Indicates which SRC is currently selected by the glitchless mux (one-hot).\n
pub const CLK_SYS_SELECTED = Register(CLK_SYS_SELECTED_val).init(base_address + 0x44);

/// CLK_SYS_DIV
const CLK_SYS_DIV_val = packed struct {
/// FRAC [0:7]
/// Fractional component of the divisor
FRAC: u8 = 0,
/// INT [8:31]
/// Integer component of the divisor, 0 -&gt; divide by 2^16
INT: u24 = 1,
};
/// Clock divisor, can be changed on-the-fly
pub const CLK_SYS_DIV = Register(CLK_SYS_DIV_val).init(base_address + 0x40);

/// CLK_SYS_CTRL
const CLK_SYS_CTRL_val = packed struct {
/// SRC [0:0]
/// Selects the clock source glitchlessly, can be changed on-the-fly
SRC: u1 = 0,
/// unused [1:4]
_unused1: u4 = 0,
/// AUXSRC [5:7]
/// Selects the auxiliary clock source, will glitch when switching
AUXSRC: u3 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Clock control, can be changed on-the-fly (except for auxsrc)
pub const CLK_SYS_CTRL = Register(CLK_SYS_CTRL_val).init(base_address + 0x3c);

/// CLK_REF_SELECTED
const CLK_REF_SELECTED_val = packed struct {
CLK_REF_SELECTED_0: u8 = 1,
CLK_REF_SELECTED_1: u8 = 0,
CLK_REF_SELECTED_2: u8 = 0,
CLK_REF_SELECTED_3: u8 = 0,
};
/// Indicates which SRC is currently selected by the glitchless mux (one-hot).\n
pub const CLK_REF_SELECTED = Register(CLK_REF_SELECTED_val).init(base_address + 0x38);

/// CLK_REF_DIV
const CLK_REF_DIV_val = packed struct {
/// unused [0:7]
_unused0: u8 = 0,
/// INT [8:9]
/// Integer component of the divisor, 0 -&gt; divide by 2^16
INT: u2 = 1,
/// unused [10:31]
_unused10: u6 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Clock divisor, can be changed on-the-fly
pub const CLK_REF_DIV = Register(CLK_REF_DIV_val).init(base_address + 0x34);

/// CLK_REF_CTRL
const CLK_REF_CTRL_val = packed struct {
/// SRC [0:1]
/// Selects the clock source glitchlessly, can be changed on-the-fly
SRC: u2 = 0,
/// unused [2:4]
_unused2: u3 = 0,
/// AUXSRC [5:6]
/// Selects the auxiliary clock source, will glitch when switching
AUXSRC: u2 = 0,
/// unused [7:31]
_unused7: u1 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Clock control, can be changed on-the-fly (except for auxsrc)
pub const CLK_REF_CTRL = Register(CLK_REF_CTRL_val).init(base_address + 0x30);

/// CLK_GPOUT3_SELECTED
const CLK_GPOUT3_SELECTED_val = packed struct {
CLK_GPOUT3_SELECTED_0: u8 = 1,
CLK_GPOUT3_SELECTED_1: u8 = 0,
CLK_GPOUT3_SELECTED_2: u8 = 0,
CLK_GPOUT3_SELECTED_3: u8 = 0,
};
/// Indicates which SRC is currently selected by the glitchless mux (one-hot).\n
pub const CLK_GPOUT3_SELECTED = Register(CLK_GPOUT3_SELECTED_val).init(base_address + 0x2c);

/// CLK_GPOUT3_DIV
const CLK_GPOUT3_DIV_val = packed struct {
/// FRAC [0:7]
/// Fractional component of the divisor
FRAC: u8 = 0,
/// INT [8:31]
/// Integer component of the divisor, 0 -&gt; divide by 2^16
INT: u24 = 1,
};
/// Clock divisor, can be changed on-the-fly
pub const CLK_GPOUT3_DIV = Register(CLK_GPOUT3_DIV_val).init(base_address + 0x28);

/// CLK_GPOUT3_CTRL
const CLK_GPOUT3_CTRL_val = packed struct {
/// unused [0:4]
_unused0: u5 = 0,
/// AUXSRC [5:8]
/// Selects the auxiliary clock source, will glitch when switching
AUXSRC: u4 = 0,
/// unused [9:9]
_unused9: u1 = 0,
/// KILL [10:10]
/// Asynchronously kills the clock generator
KILL: u1 = 0,
/// ENABLE [11:11]
/// Starts and stops the clock generator cleanly
ENABLE: u1 = 0,
/// DC50 [12:12]
/// Enables duty cycle correction for odd divisors
DC50: u1 = 0,
/// unused [13:15]
_unused13: u3 = 0,
/// PHASE [16:17]
/// This delays the enable signal by up to 3 cycles of the input clock\n
PHASE: u2 = 0,
/// unused [18:19]
_unused18: u2 = 0,
/// NUDGE [20:20]
/// An edge on this signal shifts the phase of the output by 1 cycle of the input clock\n
NUDGE: u1 = 0,
/// unused [21:31]
_unused21: u3 = 0,
_unused24: u8 = 0,
};
/// Clock control, can be changed on-the-fly (except for auxsrc)
pub const CLK_GPOUT3_CTRL = Register(CLK_GPOUT3_CTRL_val).init(base_address + 0x24);

/// CLK_GPOUT2_SELECTED
const CLK_GPOUT2_SELECTED_val = packed struct {
CLK_GPOUT2_SELECTED_0: u8 = 1,
CLK_GPOUT2_SELECTED_1: u8 = 0,
CLK_GPOUT2_SELECTED_2: u8 = 0,
CLK_GPOUT2_SELECTED_3: u8 = 0,
};
/// Indicates which SRC is currently selected by the glitchless mux (one-hot).\n
pub const CLK_GPOUT2_SELECTED = Register(CLK_GPOUT2_SELECTED_val).init(base_address + 0x20);

/// CLK_GPOUT2_DIV
const CLK_GPOUT2_DIV_val = packed struct {
/// FRAC [0:7]
/// Fractional component of the divisor
FRAC: u8 = 0,
/// INT [8:31]
/// Integer component of the divisor, 0 -&gt; divide by 2^16
INT: u24 = 1,
};
/// Clock divisor, can be changed on-the-fly
pub const CLK_GPOUT2_DIV = Register(CLK_GPOUT2_DIV_val).init(base_address + 0x1c);

/// CLK_GPOUT2_CTRL
const CLK_GPOUT2_CTRL_val = packed struct {
/// unused [0:4]
_unused0: u5 = 0,
/// AUXSRC [5:8]
/// Selects the auxiliary clock source, will glitch when switching
AUXSRC: u4 = 0,
/// unused [9:9]
_unused9: u1 = 0,
/// KILL [10:10]
/// Asynchronously kills the clock generator
KILL: u1 = 0,
/// ENABLE [11:11]
/// Starts and stops the clock generator cleanly
ENABLE: u1 = 0,
/// DC50 [12:12]
/// Enables duty cycle correction for odd divisors
DC50: u1 = 0,
/// unused [13:15]
_unused13: u3 = 0,
/// PHASE [16:17]
/// This delays the enable signal by up to 3 cycles of the input clock\n
PHASE: u2 = 0,
/// unused [18:19]
_unused18: u2 = 0,
/// NUDGE [20:20]
/// An edge on this signal shifts the phase of the output by 1 cycle of the input clock\n
NUDGE: u1 = 0,
/// unused [21:31]
_unused21: u3 = 0,
_unused24: u8 = 0,
};
/// Clock control, can be changed on-the-fly (except for auxsrc)
pub const CLK_GPOUT2_CTRL = Register(CLK_GPOUT2_CTRL_val).init(base_address + 0x18);

/// CLK_GPOUT1_SELECTED
const CLK_GPOUT1_SELECTED_val = packed struct {
CLK_GPOUT1_SELECTED_0: u8 = 1,
CLK_GPOUT1_SELECTED_1: u8 = 0,
CLK_GPOUT1_SELECTED_2: u8 = 0,
CLK_GPOUT1_SELECTED_3: u8 = 0,
};
/// Indicates which SRC is currently selected by the glitchless mux (one-hot).\n
pub const CLK_GPOUT1_SELECTED = Register(CLK_GPOUT1_SELECTED_val).init(base_address + 0x14);

/// CLK_GPOUT1_DIV
const CLK_GPOUT1_DIV_val = packed struct {
/// FRAC [0:7]
/// Fractional component of the divisor
FRAC: u8 = 0,
/// INT [8:31]
/// Integer component of the divisor, 0 -&gt; divide by 2^16
INT: u24 = 1,
};
/// Clock divisor, can be changed on-the-fly
pub const CLK_GPOUT1_DIV = Register(CLK_GPOUT1_DIV_val).init(base_address + 0x10);

/// CLK_GPOUT1_CTRL
const CLK_GPOUT1_CTRL_val = packed struct {
/// unused [0:4]
_unused0: u5 = 0,
/// AUXSRC [5:8]
/// Selects the auxiliary clock source, will glitch when switching
AUXSRC: u4 = 0,
/// unused [9:9]
_unused9: u1 = 0,
/// KILL [10:10]
/// Asynchronously kills the clock generator
KILL: u1 = 0,
/// ENABLE [11:11]
/// Starts and stops the clock generator cleanly
ENABLE: u1 = 0,
/// DC50 [12:12]
/// Enables duty cycle correction for odd divisors
DC50: u1 = 0,
/// unused [13:15]
_unused13: u3 = 0,
/// PHASE [16:17]
/// This delays the enable signal by up to 3 cycles of the input clock\n
PHASE: u2 = 0,
/// unused [18:19]
_unused18: u2 = 0,
/// NUDGE [20:20]
/// An edge on this signal shifts the phase of the output by 1 cycle of the input clock\n
NUDGE: u1 = 0,
/// unused [21:31]
_unused21: u3 = 0,
_unused24: u8 = 0,
};
/// Clock control, can be changed on-the-fly (except for auxsrc)
pub const CLK_GPOUT1_CTRL = Register(CLK_GPOUT1_CTRL_val).init(base_address + 0xc);

/// CLK_GPOUT0_SELECTED
const CLK_GPOUT0_SELECTED_val = packed struct {
CLK_GPOUT0_SELECTED_0: u8 = 1,
CLK_GPOUT0_SELECTED_1: u8 = 0,
CLK_GPOUT0_SELECTED_2: u8 = 0,
CLK_GPOUT0_SELECTED_3: u8 = 0,
};
/// Indicates which SRC is currently selected by the glitchless mux (one-hot).\n
pub const CLK_GPOUT0_SELECTED = Register(CLK_GPOUT0_SELECTED_val).init(base_address + 0x8);

/// CLK_GPOUT0_DIV
const CLK_GPOUT0_DIV_val = packed struct {
/// FRAC [0:7]
/// Fractional component of the divisor
FRAC: u8 = 0,
/// INT [8:31]
/// Integer component of the divisor, 0 -&gt; divide by 2^16
INT: u24 = 1,
};
/// Clock divisor, can be changed on-the-fly
pub const CLK_GPOUT0_DIV = Register(CLK_GPOUT0_DIV_val).init(base_address + 0x4);

/// CLK_GPOUT0_CTRL
const CLK_GPOUT0_CTRL_val = packed struct {
/// unused [0:4]
_unused0: u5 = 0,
/// AUXSRC [5:8]
/// Selects the auxiliary clock source, will glitch when switching
AUXSRC: u4 = 0,
/// unused [9:9]
_unused9: u1 = 0,
/// KILL [10:10]
/// Asynchronously kills the clock generator
KILL: u1 = 0,
/// ENABLE [11:11]
/// Starts and stops the clock generator cleanly
ENABLE: u1 = 0,
/// DC50 [12:12]
/// Enables duty cycle correction for odd divisors
DC50: u1 = 0,
/// unused [13:15]
_unused13: u3 = 0,
/// PHASE [16:17]
/// This delays the enable signal by up to 3 cycles of the input clock\n
PHASE: u2 = 0,
/// unused [18:19]
_unused18: u2 = 0,
/// NUDGE [20:20]
/// An edge on this signal shifts the phase of the output by 1 cycle of the input clock\n
NUDGE: u1 = 0,
/// unused [21:31]
_unused21: u3 = 0,
_unused24: u8 = 0,
};
/// Clock control, can be changed on-the-fly (except for auxsrc)
pub const CLK_GPOUT0_CTRL = Register(CLK_GPOUT0_CTRL_val).init(base_address + 0x0);
};

/// No description
pub const RESETS = struct {

const base_address = 0x4000c000;
/// RESET_DONE
const RESET_DONE_val = packed struct {
/// adc [0:0]
/// No description
adc: u1 = 0,
/// busctrl [1:1]
/// No description
busctrl: u1 = 0,
/// dma [2:2]
/// No description
dma: u1 = 0,
/// i2c0 [3:3]
/// No description
i2c0: u1 = 0,
/// i2c1 [4:4]
/// No description
i2c1: u1 = 0,
/// io_bank0 [5:5]
/// No description
io_bank0: u1 = 0,
/// io_qspi [6:6]
/// No description
io_qspi: u1 = 0,
/// jtag [7:7]
/// No description
jtag: u1 = 0,
/// pads_bank0 [8:8]
/// No description
pads_bank0: u1 = 0,
/// pads_qspi [9:9]
/// No description
pads_qspi: u1 = 0,
/// pio0 [10:10]
/// No description
pio0: u1 = 0,
/// pio1 [11:11]
/// No description
pio1: u1 = 0,
/// pll_sys [12:12]
/// No description
pll_sys: u1 = 0,
/// pll_usb [13:13]
/// No description
pll_usb: u1 = 0,
/// pwm [14:14]
/// No description
pwm: u1 = 0,
/// rtc [15:15]
/// No description
rtc: u1 = 0,
/// spi0 [16:16]
/// No description
spi0: u1 = 0,
/// spi1 [17:17]
/// No description
spi1: u1 = 0,
/// syscfg [18:18]
/// No description
syscfg: u1 = 0,
/// sysinfo [19:19]
/// No description
sysinfo: u1 = 0,
/// tbman [20:20]
/// No description
tbman: u1 = 0,
/// timer [21:21]
/// No description
timer: u1 = 0,
/// uart0 [22:22]
/// No description
uart0: u1 = 0,
/// uart1 [23:23]
/// No description
uart1: u1 = 0,
/// usbctrl [24:24]
/// No description
usbctrl: u1 = 0,
/// unused [25:31]
_unused25: u7 = 0,
};
/// Reset done. If a bit is set then a reset done signal has been returned by the peripheral. This indicates that the peripheral's registers are ready to be accessed.
pub const RESET_DONE = Register(RESET_DONE_val).init(base_address + 0x8);

/// WDSEL
const WDSEL_val = packed struct {
/// adc [0:0]
/// No description
adc: u1 = 0,
/// busctrl [1:1]
/// No description
busctrl: u1 = 0,
/// dma [2:2]
/// No description
dma: u1 = 0,
/// i2c0 [3:3]
/// No description
i2c0: u1 = 0,
/// i2c1 [4:4]
/// No description
i2c1: u1 = 0,
/// io_bank0 [5:5]
/// No description
io_bank0: u1 = 0,
/// io_qspi [6:6]
/// No description
io_qspi: u1 = 0,
/// jtag [7:7]
/// No description
jtag: u1 = 0,
/// pads_bank0 [8:8]
/// No description
pads_bank0: u1 = 0,
/// pads_qspi [9:9]
/// No description
pads_qspi: u1 = 0,
/// pio0 [10:10]
/// No description
pio0: u1 = 0,
/// pio1 [11:11]
/// No description
pio1: u1 = 0,
/// pll_sys [12:12]
/// No description
pll_sys: u1 = 0,
/// pll_usb [13:13]
/// No description
pll_usb: u1 = 0,
/// pwm [14:14]
/// No description
pwm: u1 = 0,
/// rtc [15:15]
/// No description
rtc: u1 = 0,
/// spi0 [16:16]
/// No description
spi0: u1 = 0,
/// spi1 [17:17]
/// No description
spi1: u1 = 0,
/// syscfg [18:18]
/// No description
syscfg: u1 = 0,
/// sysinfo [19:19]
/// No description
sysinfo: u1 = 0,
/// tbman [20:20]
/// No description
tbman: u1 = 0,
/// timer [21:21]
/// No description
timer: u1 = 0,
/// uart0 [22:22]
/// No description
uart0: u1 = 0,
/// uart1 [23:23]
/// No description
uart1: u1 = 0,
/// usbctrl [24:24]
/// No description
usbctrl: u1 = 0,
/// unused [25:31]
_unused25: u7 = 0,
};
/// Watchdog select. If a bit is set then the watchdog will reset this peripheral when the watchdog fires.
pub const WDSEL = Register(WDSEL_val).init(base_address + 0x4);

/// RESET
const RESET_val = packed struct {
/// adc [0:0]
/// No description
adc: u1 = 1,
/// busctrl [1:1]
/// No description
busctrl: u1 = 1,
/// dma [2:2]
/// No description
dma: u1 = 1,
/// i2c0 [3:3]
/// No description
i2c0: u1 = 1,
/// i2c1 [4:4]
/// No description
i2c1: u1 = 1,
/// io_bank0 [5:5]
/// No description
io_bank0: u1 = 1,
/// io_qspi [6:6]
/// No description
io_qspi: u1 = 1,
/// jtag [7:7]
/// No description
jtag: u1 = 1,
/// pads_bank0 [8:8]
/// No description
pads_bank0: u1 = 1,
/// pads_qspi [9:9]
/// No description
pads_qspi: u1 = 1,
/// pio0 [10:10]
/// No description
pio0: u1 = 1,
/// pio1 [11:11]
/// No description
pio1: u1 = 1,
/// pll_sys [12:12]
/// No description
pll_sys: u1 = 1,
/// pll_usb [13:13]
/// No description
pll_usb: u1 = 1,
/// pwm [14:14]
/// No description
pwm: u1 = 1,
/// rtc [15:15]
/// No description
rtc: u1 = 1,
/// spi0 [16:16]
/// No description
spi0: u1 = 1,
/// spi1 [17:17]
/// No description
spi1: u1 = 1,
/// syscfg [18:18]
/// No description
syscfg: u1 = 1,
/// sysinfo [19:19]
/// No description
sysinfo: u1 = 1,
/// tbman [20:20]
/// No description
tbman: u1 = 1,
/// timer [21:21]
/// No description
timer: u1 = 1,
/// uart0 [22:22]
/// No description
uart0: u1 = 1,
/// uart1 [23:23]
/// No description
uart1: u1 = 1,
/// usbctrl [24:24]
/// No description
usbctrl: u1 = 1,
/// unused [25:31]
_unused25: u7 = 0,
};
/// Reset control. If a bit is set it means the peripheral is in reset. 0 means the peripheral's reset is deasserted.
pub const RESET = Register(RESET_val).init(base_address + 0x0);
};

/// No description
pub const PSM = struct {

const base_address = 0x40010000;
/// DONE
const DONE_val = packed struct {
/// rosc [0:0]
/// No description
rosc: u1 = 0,
/// xosc [1:1]
/// No description
xosc: u1 = 0,
/// clocks [2:2]
/// No description
clocks: u1 = 0,
/// resets [3:3]
/// No description
resets: u1 = 0,
/// busfabric [4:4]
/// No description
busfabric: u1 = 0,
/// rom [5:5]
/// No description
rom: u1 = 0,
/// sram0 [6:6]
/// No description
sram0: u1 = 0,
/// sram1 [7:7]
/// No description
sram1: u1 = 0,
/// sram2 [8:8]
/// No description
sram2: u1 = 0,
/// sram3 [9:9]
/// No description
sram3: u1 = 0,
/// sram4 [10:10]
/// No description
sram4: u1 = 0,
/// sram5 [11:11]
/// No description
sram5: u1 = 0,
/// xip [12:12]
/// No description
xip: u1 = 0,
/// vreg_and_chip_reset [13:13]
/// No description
vreg_and_chip_reset: u1 = 0,
/// sio [14:14]
/// No description
sio: u1 = 0,
/// proc0 [15:15]
/// No description
proc0: u1 = 0,
/// proc1 [16:16]
/// No description
proc1: u1 = 0,
/// unused [17:31]
_unused17: u7 = 0,
_unused24: u8 = 0,
};
/// Indicates the peripheral's registers are ready to access.
pub const DONE = Register(DONE_val).init(base_address + 0xc);

/// WDSEL
const WDSEL_val = packed struct {
/// rosc [0:0]
/// No description
rosc: u1 = 0,
/// xosc [1:1]
/// No description
xosc: u1 = 0,
/// clocks [2:2]
/// No description
clocks: u1 = 0,
/// resets [3:3]
/// No description
resets: u1 = 0,
/// busfabric [4:4]
/// No description
busfabric: u1 = 0,
/// rom [5:5]
/// No description
rom: u1 = 0,
/// sram0 [6:6]
/// No description
sram0: u1 = 0,
/// sram1 [7:7]
/// No description
sram1: u1 = 0,
/// sram2 [8:8]
/// No description
sram2: u1 = 0,
/// sram3 [9:9]
/// No description
sram3: u1 = 0,
/// sram4 [10:10]
/// No description
sram4: u1 = 0,
/// sram5 [11:11]
/// No description
sram5: u1 = 0,
/// xip [12:12]
/// No description
xip: u1 = 0,
/// vreg_and_chip_reset [13:13]
/// No description
vreg_and_chip_reset: u1 = 0,
/// sio [14:14]
/// No description
sio: u1 = 0,
/// proc0 [15:15]
/// No description
proc0: u1 = 0,
/// proc1 [16:16]
/// No description
proc1: u1 = 0,
/// unused [17:31]
_unused17: u7 = 0,
_unused24: u8 = 0,
};
/// Set to 1 if this peripheral should be reset when the watchdog fires.
pub const WDSEL = Register(WDSEL_val).init(base_address + 0x8);

/// FRCE_OFF
const FRCE_OFF_val = packed struct {
/// rosc [0:0]
/// No description
rosc: u1 = 0,
/// xosc [1:1]
/// No description
xosc: u1 = 0,
/// clocks [2:2]
/// No description
clocks: u1 = 0,
/// resets [3:3]
/// No description
resets: u1 = 0,
/// busfabric [4:4]
/// No description
busfabric: u1 = 0,
/// rom [5:5]
/// No description
rom: u1 = 0,
/// sram0 [6:6]
/// No description
sram0: u1 = 0,
/// sram1 [7:7]
/// No description
sram1: u1 = 0,
/// sram2 [8:8]
/// No description
sram2: u1 = 0,
/// sram3 [9:9]
/// No description
sram3: u1 = 0,
/// sram4 [10:10]
/// No description
sram4: u1 = 0,
/// sram5 [11:11]
/// No description
sram5: u1 = 0,
/// xip [12:12]
/// No description
xip: u1 = 0,
/// vreg_and_chip_reset [13:13]
/// No description
vreg_and_chip_reset: u1 = 0,
/// sio [14:14]
/// No description
sio: u1 = 0,
/// proc0 [15:15]
/// No description
proc0: u1 = 0,
/// proc1 [16:16]
/// No description
proc1: u1 = 0,
/// unused [17:31]
_unused17: u7 = 0,
_unused24: u8 = 0,
};
/// Force into reset (i.e. power it off)
pub const FRCE_OFF = Register(FRCE_OFF_val).init(base_address + 0x4);

/// FRCE_ON
const FRCE_ON_val = packed struct {
/// rosc [0:0]
/// No description
rosc: u1 = 0,
/// xosc [1:1]
/// No description
xosc: u1 = 0,
/// clocks [2:2]
/// No description
clocks: u1 = 0,
/// resets [3:3]
/// No description
resets: u1 = 0,
/// busfabric [4:4]
/// No description
busfabric: u1 = 0,
/// rom [5:5]
/// No description
rom: u1 = 0,
/// sram0 [6:6]
/// No description
sram0: u1 = 0,
/// sram1 [7:7]
/// No description
sram1: u1 = 0,
/// sram2 [8:8]
/// No description
sram2: u1 = 0,
/// sram3 [9:9]
/// No description
sram3: u1 = 0,
/// sram4 [10:10]
/// No description
sram4: u1 = 0,
/// sram5 [11:11]
/// No description
sram5: u1 = 0,
/// xip [12:12]
/// No description
xip: u1 = 0,
/// vreg_and_chip_reset [13:13]
/// No description
vreg_and_chip_reset: u1 = 0,
/// sio [14:14]
/// No description
sio: u1 = 0,
/// proc0 [15:15]
/// No description
proc0: u1 = 0,
/// proc1 [16:16]
/// No description
proc1: u1 = 0,
/// unused [17:31]
_unused17: u7 = 0,
_unused24: u8 = 0,
};
/// Force block out of reset (i.e. power it on)
pub const FRCE_ON = Register(FRCE_ON_val).init(base_address + 0x0);
};

/// No description
pub const IO_BANK0 = struct {

const base_address = 0x40014000;
/// DORMANT_WAKE_INTS3
const DORMANT_WAKE_INTS3_val = packed struct {
/// GPIO24_LEVEL_LOW [0:0]
/// No description
GPIO24_LEVEL_LOW: u1 = 0,
/// GPIO24_LEVEL_HIGH [1:1]
/// No description
GPIO24_LEVEL_HIGH: u1 = 0,
/// GPIO24_EDGE_LOW [2:2]
/// No description
GPIO24_EDGE_LOW: u1 = 0,
/// GPIO24_EDGE_HIGH [3:3]
/// No description
GPIO24_EDGE_HIGH: u1 = 0,
/// GPIO25_LEVEL_LOW [4:4]
/// No description
GPIO25_LEVEL_LOW: u1 = 0,
/// GPIO25_LEVEL_HIGH [5:5]
/// No description
GPIO25_LEVEL_HIGH: u1 = 0,
/// GPIO25_EDGE_LOW [6:6]
/// No description
GPIO25_EDGE_LOW: u1 = 0,
/// GPIO25_EDGE_HIGH [7:7]
/// No description
GPIO25_EDGE_HIGH: u1 = 0,
/// GPIO26_LEVEL_LOW [8:8]
/// No description
GPIO26_LEVEL_LOW: u1 = 0,
/// GPIO26_LEVEL_HIGH [9:9]
/// No description
GPIO26_LEVEL_HIGH: u1 = 0,
/// GPIO26_EDGE_LOW [10:10]
/// No description
GPIO26_EDGE_LOW: u1 = 0,
/// GPIO26_EDGE_HIGH [11:11]
/// No description
GPIO26_EDGE_HIGH: u1 = 0,
/// GPIO27_LEVEL_LOW [12:12]
/// No description
GPIO27_LEVEL_LOW: u1 = 0,
/// GPIO27_LEVEL_HIGH [13:13]
/// No description
GPIO27_LEVEL_HIGH: u1 = 0,
/// GPIO27_EDGE_LOW [14:14]
/// No description
GPIO27_EDGE_LOW: u1 = 0,
/// GPIO27_EDGE_HIGH [15:15]
/// No description
GPIO27_EDGE_HIGH: u1 = 0,
/// GPIO28_LEVEL_LOW [16:16]
/// No description
GPIO28_LEVEL_LOW: u1 = 0,
/// GPIO28_LEVEL_HIGH [17:17]
/// No description
GPIO28_LEVEL_HIGH: u1 = 0,
/// GPIO28_EDGE_LOW [18:18]
/// No description
GPIO28_EDGE_LOW: u1 = 0,
/// GPIO28_EDGE_HIGH [19:19]
/// No description
GPIO28_EDGE_HIGH: u1 = 0,
/// GPIO29_LEVEL_LOW [20:20]
/// No description
GPIO29_LEVEL_LOW: u1 = 0,
/// GPIO29_LEVEL_HIGH [21:21]
/// No description
GPIO29_LEVEL_HIGH: u1 = 0,
/// GPIO29_EDGE_LOW [22:22]
/// No description
GPIO29_EDGE_LOW: u1 = 0,
/// GPIO29_EDGE_HIGH [23:23]
/// No description
GPIO29_EDGE_HIGH: u1 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// Interrupt status after masking &amp; forcing for dormant_wake
pub const DORMANT_WAKE_INTS3 = Register(DORMANT_WAKE_INTS3_val).init(base_address + 0x18c);

/// DORMANT_WAKE_INTS2
const DORMANT_WAKE_INTS2_val = packed struct {
/// GPIO16_LEVEL_LOW [0:0]
/// No description
GPIO16_LEVEL_LOW: u1 = 0,
/// GPIO16_LEVEL_HIGH [1:1]
/// No description
GPIO16_LEVEL_HIGH: u1 = 0,
/// GPIO16_EDGE_LOW [2:2]
/// No description
GPIO16_EDGE_LOW: u1 = 0,
/// GPIO16_EDGE_HIGH [3:3]
/// No description
GPIO16_EDGE_HIGH: u1 = 0,
/// GPIO17_LEVEL_LOW [4:4]
/// No description
GPIO17_LEVEL_LOW: u1 = 0,
/// GPIO17_LEVEL_HIGH [5:5]
/// No description
GPIO17_LEVEL_HIGH: u1 = 0,
/// GPIO17_EDGE_LOW [6:6]
/// No description
GPIO17_EDGE_LOW: u1 = 0,
/// GPIO17_EDGE_HIGH [7:7]
/// No description
GPIO17_EDGE_HIGH: u1 = 0,
/// GPIO18_LEVEL_LOW [8:8]
/// No description
GPIO18_LEVEL_LOW: u1 = 0,
/// GPIO18_LEVEL_HIGH [9:9]
/// No description
GPIO18_LEVEL_HIGH: u1 = 0,
/// GPIO18_EDGE_LOW [10:10]
/// No description
GPIO18_EDGE_LOW: u1 = 0,
/// GPIO18_EDGE_HIGH [11:11]
/// No description
GPIO18_EDGE_HIGH: u1 = 0,
/// GPIO19_LEVEL_LOW [12:12]
/// No description
GPIO19_LEVEL_LOW: u1 = 0,
/// GPIO19_LEVEL_HIGH [13:13]
/// No description
GPIO19_LEVEL_HIGH: u1 = 0,
/// GPIO19_EDGE_LOW [14:14]
/// No description
GPIO19_EDGE_LOW: u1 = 0,
/// GPIO19_EDGE_HIGH [15:15]
/// No description
GPIO19_EDGE_HIGH: u1 = 0,
/// GPIO20_LEVEL_LOW [16:16]
/// No description
GPIO20_LEVEL_LOW: u1 = 0,
/// GPIO20_LEVEL_HIGH [17:17]
/// No description
GPIO20_LEVEL_HIGH: u1 = 0,
/// GPIO20_EDGE_LOW [18:18]
/// No description
GPIO20_EDGE_LOW: u1 = 0,
/// GPIO20_EDGE_HIGH [19:19]
/// No description
GPIO20_EDGE_HIGH: u1 = 0,
/// GPIO21_LEVEL_LOW [20:20]
/// No description
GPIO21_LEVEL_LOW: u1 = 0,
/// GPIO21_LEVEL_HIGH [21:21]
/// No description
GPIO21_LEVEL_HIGH: u1 = 0,
/// GPIO21_EDGE_LOW [22:22]
/// No description
GPIO21_EDGE_LOW: u1 = 0,
/// GPIO21_EDGE_HIGH [23:23]
/// No description
GPIO21_EDGE_HIGH: u1 = 0,
/// GPIO22_LEVEL_LOW [24:24]
/// No description
GPIO22_LEVEL_LOW: u1 = 0,
/// GPIO22_LEVEL_HIGH [25:25]
/// No description
GPIO22_LEVEL_HIGH: u1 = 0,
/// GPIO22_EDGE_LOW [26:26]
/// No description
GPIO22_EDGE_LOW: u1 = 0,
/// GPIO22_EDGE_HIGH [27:27]
/// No description
GPIO22_EDGE_HIGH: u1 = 0,
/// GPIO23_LEVEL_LOW [28:28]
/// No description
GPIO23_LEVEL_LOW: u1 = 0,
/// GPIO23_LEVEL_HIGH [29:29]
/// No description
GPIO23_LEVEL_HIGH: u1 = 0,
/// GPIO23_EDGE_LOW [30:30]
/// No description
GPIO23_EDGE_LOW: u1 = 0,
/// GPIO23_EDGE_HIGH [31:31]
/// No description
GPIO23_EDGE_HIGH: u1 = 0,
};
/// Interrupt status after masking &amp; forcing for dormant_wake
pub const DORMANT_WAKE_INTS2 = Register(DORMANT_WAKE_INTS2_val).init(base_address + 0x188);

/// DORMANT_WAKE_INTS1
const DORMANT_WAKE_INTS1_val = packed struct {
/// GPIO8_LEVEL_LOW [0:0]
/// No description
GPIO8_LEVEL_LOW: u1 = 0,
/// GPIO8_LEVEL_HIGH [1:1]
/// No description
GPIO8_LEVEL_HIGH: u1 = 0,
/// GPIO8_EDGE_LOW [2:2]
/// No description
GPIO8_EDGE_LOW: u1 = 0,
/// GPIO8_EDGE_HIGH [3:3]
/// No description
GPIO8_EDGE_HIGH: u1 = 0,
/// GPIO9_LEVEL_LOW [4:4]
/// No description
GPIO9_LEVEL_LOW: u1 = 0,
/// GPIO9_LEVEL_HIGH [5:5]
/// No description
GPIO9_LEVEL_HIGH: u1 = 0,
/// GPIO9_EDGE_LOW [6:6]
/// No description
GPIO9_EDGE_LOW: u1 = 0,
/// GPIO9_EDGE_HIGH [7:7]
/// No description
GPIO9_EDGE_HIGH: u1 = 0,
/// GPIO10_LEVEL_LOW [8:8]
/// No description
GPIO10_LEVEL_LOW: u1 = 0,
/// GPIO10_LEVEL_HIGH [9:9]
/// No description
GPIO10_LEVEL_HIGH: u1 = 0,
/// GPIO10_EDGE_LOW [10:10]
/// No description
GPIO10_EDGE_LOW: u1 = 0,
/// GPIO10_EDGE_HIGH [11:11]
/// No description
GPIO10_EDGE_HIGH: u1 = 0,
/// GPIO11_LEVEL_LOW [12:12]
/// No description
GPIO11_LEVEL_LOW: u1 = 0,
/// GPIO11_LEVEL_HIGH [13:13]
/// No description
GPIO11_LEVEL_HIGH: u1 = 0,
/// GPIO11_EDGE_LOW [14:14]
/// No description
GPIO11_EDGE_LOW: u1 = 0,
/// GPIO11_EDGE_HIGH [15:15]
/// No description
GPIO11_EDGE_HIGH: u1 = 0,
/// GPIO12_LEVEL_LOW [16:16]
/// No description
GPIO12_LEVEL_LOW: u1 = 0,
/// GPIO12_LEVEL_HIGH [17:17]
/// No description
GPIO12_LEVEL_HIGH: u1 = 0,
/// GPIO12_EDGE_LOW [18:18]
/// No description
GPIO12_EDGE_LOW: u1 = 0,
/// GPIO12_EDGE_HIGH [19:19]
/// No description
GPIO12_EDGE_HIGH: u1 = 0,
/// GPIO13_LEVEL_LOW [20:20]
/// No description
GPIO13_LEVEL_LOW: u1 = 0,
/// GPIO13_LEVEL_HIGH [21:21]
/// No description
GPIO13_LEVEL_HIGH: u1 = 0,
/// GPIO13_EDGE_LOW [22:22]
/// No description
GPIO13_EDGE_LOW: u1 = 0,
/// GPIO13_EDGE_HIGH [23:23]
/// No description
GPIO13_EDGE_HIGH: u1 = 0,
/// GPIO14_LEVEL_LOW [24:24]
/// No description
GPIO14_LEVEL_LOW: u1 = 0,
/// GPIO14_LEVEL_HIGH [25:25]
/// No description
GPIO14_LEVEL_HIGH: u1 = 0,
/// GPIO14_EDGE_LOW [26:26]
/// No description
GPIO14_EDGE_LOW: u1 = 0,
/// GPIO14_EDGE_HIGH [27:27]
/// No description
GPIO14_EDGE_HIGH: u1 = 0,
/// GPIO15_LEVEL_LOW [28:28]
/// No description
GPIO15_LEVEL_LOW: u1 = 0,
/// GPIO15_LEVEL_HIGH [29:29]
/// No description
GPIO15_LEVEL_HIGH: u1 = 0,
/// GPIO15_EDGE_LOW [30:30]
/// No description
GPIO15_EDGE_LOW: u1 = 0,
/// GPIO15_EDGE_HIGH [31:31]
/// No description
GPIO15_EDGE_HIGH: u1 = 0,
};
/// Interrupt status after masking &amp; forcing for dormant_wake
pub const DORMANT_WAKE_INTS1 = Register(DORMANT_WAKE_INTS1_val).init(base_address + 0x184);

/// DORMANT_WAKE_INTS0
const DORMANT_WAKE_INTS0_val = packed struct {
/// GPIO0_LEVEL_LOW [0:0]
/// No description
GPIO0_LEVEL_LOW: u1 = 0,
/// GPIO0_LEVEL_HIGH [1:1]
/// No description
GPIO0_LEVEL_HIGH: u1 = 0,
/// GPIO0_EDGE_LOW [2:2]
/// No description
GPIO0_EDGE_LOW: u1 = 0,
/// GPIO0_EDGE_HIGH [3:3]
/// No description
GPIO0_EDGE_HIGH: u1 = 0,
/// GPIO1_LEVEL_LOW [4:4]
/// No description
GPIO1_LEVEL_LOW: u1 = 0,
/// GPIO1_LEVEL_HIGH [5:5]
/// No description
GPIO1_LEVEL_HIGH: u1 = 0,
/// GPIO1_EDGE_LOW [6:6]
/// No description
GPIO1_EDGE_LOW: u1 = 0,
/// GPIO1_EDGE_HIGH [7:7]
/// No description
GPIO1_EDGE_HIGH: u1 = 0,
/// GPIO2_LEVEL_LOW [8:8]
/// No description
GPIO2_LEVEL_LOW: u1 = 0,
/// GPIO2_LEVEL_HIGH [9:9]
/// No description
GPIO2_LEVEL_HIGH: u1 = 0,
/// GPIO2_EDGE_LOW [10:10]
/// No description
GPIO2_EDGE_LOW: u1 = 0,
/// GPIO2_EDGE_HIGH [11:11]
/// No description
GPIO2_EDGE_HIGH: u1 = 0,
/// GPIO3_LEVEL_LOW [12:12]
/// No description
GPIO3_LEVEL_LOW: u1 = 0,
/// GPIO3_LEVEL_HIGH [13:13]
/// No description
GPIO3_LEVEL_HIGH: u1 = 0,
/// GPIO3_EDGE_LOW [14:14]
/// No description
GPIO3_EDGE_LOW: u1 = 0,
/// GPIO3_EDGE_HIGH [15:15]
/// No description
GPIO3_EDGE_HIGH: u1 = 0,
/// GPIO4_LEVEL_LOW [16:16]
/// No description
GPIO4_LEVEL_LOW: u1 = 0,
/// GPIO4_LEVEL_HIGH [17:17]
/// No description
GPIO4_LEVEL_HIGH: u1 = 0,
/// GPIO4_EDGE_LOW [18:18]
/// No description
GPIO4_EDGE_LOW: u1 = 0,
/// GPIO4_EDGE_HIGH [19:19]
/// No description
GPIO4_EDGE_HIGH: u1 = 0,
/// GPIO5_LEVEL_LOW [20:20]
/// No description
GPIO5_LEVEL_LOW: u1 = 0,
/// GPIO5_LEVEL_HIGH [21:21]
/// No description
GPIO5_LEVEL_HIGH: u1 = 0,
/// GPIO5_EDGE_LOW [22:22]
/// No description
GPIO5_EDGE_LOW: u1 = 0,
/// GPIO5_EDGE_HIGH [23:23]
/// No description
GPIO5_EDGE_HIGH: u1 = 0,
/// GPIO6_LEVEL_LOW [24:24]
/// No description
GPIO6_LEVEL_LOW: u1 = 0,
/// GPIO6_LEVEL_HIGH [25:25]
/// No description
GPIO6_LEVEL_HIGH: u1 = 0,
/// GPIO6_EDGE_LOW [26:26]
/// No description
GPIO6_EDGE_LOW: u1 = 0,
/// GPIO6_EDGE_HIGH [27:27]
/// No description
GPIO6_EDGE_HIGH: u1 = 0,
/// GPIO7_LEVEL_LOW [28:28]
/// No description
GPIO7_LEVEL_LOW: u1 = 0,
/// GPIO7_LEVEL_HIGH [29:29]
/// No description
GPIO7_LEVEL_HIGH: u1 = 0,
/// GPIO7_EDGE_LOW [30:30]
/// No description
GPIO7_EDGE_LOW: u1 = 0,
/// GPIO7_EDGE_HIGH [31:31]
/// No description
GPIO7_EDGE_HIGH: u1 = 0,
};
/// Interrupt status after masking &amp; forcing for dormant_wake
pub const DORMANT_WAKE_INTS0 = Register(DORMANT_WAKE_INTS0_val).init(base_address + 0x180);

/// DORMANT_WAKE_INTF3
const DORMANT_WAKE_INTF3_val = packed struct {
/// GPIO24_LEVEL_LOW [0:0]
/// No description
GPIO24_LEVEL_LOW: u1 = 0,
/// GPIO24_LEVEL_HIGH [1:1]
/// No description
GPIO24_LEVEL_HIGH: u1 = 0,
/// GPIO24_EDGE_LOW [2:2]
/// No description
GPIO24_EDGE_LOW: u1 = 0,
/// GPIO24_EDGE_HIGH [3:3]
/// No description
GPIO24_EDGE_HIGH: u1 = 0,
/// GPIO25_LEVEL_LOW [4:4]
/// No description
GPIO25_LEVEL_LOW: u1 = 0,
/// GPIO25_LEVEL_HIGH [5:5]
/// No description
GPIO25_LEVEL_HIGH: u1 = 0,
/// GPIO25_EDGE_LOW [6:6]
/// No description
GPIO25_EDGE_LOW: u1 = 0,
/// GPIO25_EDGE_HIGH [7:7]
/// No description
GPIO25_EDGE_HIGH: u1 = 0,
/// GPIO26_LEVEL_LOW [8:8]
/// No description
GPIO26_LEVEL_LOW: u1 = 0,
/// GPIO26_LEVEL_HIGH [9:9]
/// No description
GPIO26_LEVEL_HIGH: u1 = 0,
/// GPIO26_EDGE_LOW [10:10]
/// No description
GPIO26_EDGE_LOW: u1 = 0,
/// GPIO26_EDGE_HIGH [11:11]
/// No description
GPIO26_EDGE_HIGH: u1 = 0,
/// GPIO27_LEVEL_LOW [12:12]
/// No description
GPIO27_LEVEL_LOW: u1 = 0,
/// GPIO27_LEVEL_HIGH [13:13]
/// No description
GPIO27_LEVEL_HIGH: u1 = 0,
/// GPIO27_EDGE_LOW [14:14]
/// No description
GPIO27_EDGE_LOW: u1 = 0,
/// GPIO27_EDGE_HIGH [15:15]
/// No description
GPIO27_EDGE_HIGH: u1 = 0,
/// GPIO28_LEVEL_LOW [16:16]
/// No description
GPIO28_LEVEL_LOW: u1 = 0,
/// GPIO28_LEVEL_HIGH [17:17]
/// No description
GPIO28_LEVEL_HIGH: u1 = 0,
/// GPIO28_EDGE_LOW [18:18]
/// No description
GPIO28_EDGE_LOW: u1 = 0,
/// GPIO28_EDGE_HIGH [19:19]
/// No description
GPIO28_EDGE_HIGH: u1 = 0,
/// GPIO29_LEVEL_LOW [20:20]
/// No description
GPIO29_LEVEL_LOW: u1 = 0,
/// GPIO29_LEVEL_HIGH [21:21]
/// No description
GPIO29_LEVEL_HIGH: u1 = 0,
/// GPIO29_EDGE_LOW [22:22]
/// No description
GPIO29_EDGE_LOW: u1 = 0,
/// GPIO29_EDGE_HIGH [23:23]
/// No description
GPIO29_EDGE_HIGH: u1 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// Interrupt Force for dormant_wake
pub const DORMANT_WAKE_INTF3 = Register(DORMANT_WAKE_INTF3_val).init(base_address + 0x17c);

/// DORMANT_WAKE_INTF2
const DORMANT_WAKE_INTF2_val = packed struct {
/// GPIO16_LEVEL_LOW [0:0]
/// No description
GPIO16_LEVEL_LOW: u1 = 0,
/// GPIO16_LEVEL_HIGH [1:1]
/// No description
GPIO16_LEVEL_HIGH: u1 = 0,
/// GPIO16_EDGE_LOW [2:2]
/// No description
GPIO16_EDGE_LOW: u1 = 0,
/// GPIO16_EDGE_HIGH [3:3]
/// No description
GPIO16_EDGE_HIGH: u1 = 0,
/// GPIO17_LEVEL_LOW [4:4]
/// No description
GPIO17_LEVEL_LOW: u1 = 0,
/// GPIO17_LEVEL_HIGH [5:5]
/// No description
GPIO17_LEVEL_HIGH: u1 = 0,
/// GPIO17_EDGE_LOW [6:6]
/// No description
GPIO17_EDGE_LOW: u1 = 0,
/// GPIO17_EDGE_HIGH [7:7]
/// No description
GPIO17_EDGE_HIGH: u1 = 0,
/// GPIO18_LEVEL_LOW [8:8]
/// No description
GPIO18_LEVEL_LOW: u1 = 0,
/// GPIO18_LEVEL_HIGH [9:9]
/// No description
GPIO18_LEVEL_HIGH: u1 = 0,
/// GPIO18_EDGE_LOW [10:10]
/// No description
GPIO18_EDGE_LOW: u1 = 0,
/// GPIO18_EDGE_HIGH [11:11]
/// No description
GPIO18_EDGE_HIGH: u1 = 0,
/// GPIO19_LEVEL_LOW [12:12]
/// No description
GPIO19_LEVEL_LOW: u1 = 0,
/// GPIO19_LEVEL_HIGH [13:13]
/// No description
GPIO19_LEVEL_HIGH: u1 = 0,
/// GPIO19_EDGE_LOW [14:14]
/// No description
GPIO19_EDGE_LOW: u1 = 0,
/// GPIO19_EDGE_HIGH [15:15]
/// No description
GPIO19_EDGE_HIGH: u1 = 0,
/// GPIO20_LEVEL_LOW [16:16]
/// No description
GPIO20_LEVEL_LOW: u1 = 0,
/// GPIO20_LEVEL_HIGH [17:17]
/// No description
GPIO20_LEVEL_HIGH: u1 = 0,
/// GPIO20_EDGE_LOW [18:18]
/// No description
GPIO20_EDGE_LOW: u1 = 0,
/// GPIO20_EDGE_HIGH [19:19]
/// No description
GPIO20_EDGE_HIGH: u1 = 0,
/// GPIO21_LEVEL_LOW [20:20]
/// No description
GPIO21_LEVEL_LOW: u1 = 0,
/// GPIO21_LEVEL_HIGH [21:21]
/// No description
GPIO21_LEVEL_HIGH: u1 = 0,
/// GPIO21_EDGE_LOW [22:22]
/// No description
GPIO21_EDGE_LOW: u1 = 0,
/// GPIO21_EDGE_HIGH [23:23]
/// No description
GPIO21_EDGE_HIGH: u1 = 0,
/// GPIO22_LEVEL_LOW [24:24]
/// No description
GPIO22_LEVEL_LOW: u1 = 0,
/// GPIO22_LEVEL_HIGH [25:25]
/// No description
GPIO22_LEVEL_HIGH: u1 = 0,
/// GPIO22_EDGE_LOW [26:26]
/// No description
GPIO22_EDGE_LOW: u1 = 0,
/// GPIO22_EDGE_HIGH [27:27]
/// No description
GPIO22_EDGE_HIGH: u1 = 0,
/// GPIO23_LEVEL_LOW [28:28]
/// No description
GPIO23_LEVEL_LOW: u1 = 0,
/// GPIO23_LEVEL_HIGH [29:29]
/// No description
GPIO23_LEVEL_HIGH: u1 = 0,
/// GPIO23_EDGE_LOW [30:30]
/// No description
GPIO23_EDGE_LOW: u1 = 0,
/// GPIO23_EDGE_HIGH [31:31]
/// No description
GPIO23_EDGE_HIGH: u1 = 0,
};
/// Interrupt Force for dormant_wake
pub const DORMANT_WAKE_INTF2 = Register(DORMANT_WAKE_INTF2_val).init(base_address + 0x178);

/// DORMANT_WAKE_INTF1
const DORMANT_WAKE_INTF1_val = packed struct {
/// GPIO8_LEVEL_LOW [0:0]
/// No description
GPIO8_LEVEL_LOW: u1 = 0,
/// GPIO8_LEVEL_HIGH [1:1]
/// No description
GPIO8_LEVEL_HIGH: u1 = 0,
/// GPIO8_EDGE_LOW [2:2]
/// No description
GPIO8_EDGE_LOW: u1 = 0,
/// GPIO8_EDGE_HIGH [3:3]
/// No description
GPIO8_EDGE_HIGH: u1 = 0,
/// GPIO9_LEVEL_LOW [4:4]
/// No description
GPIO9_LEVEL_LOW: u1 = 0,
/// GPIO9_LEVEL_HIGH [5:5]
/// No description
GPIO9_LEVEL_HIGH: u1 = 0,
/// GPIO9_EDGE_LOW [6:6]
/// No description
GPIO9_EDGE_LOW: u1 = 0,
/// GPIO9_EDGE_HIGH [7:7]
/// No description
GPIO9_EDGE_HIGH: u1 = 0,
/// GPIO10_LEVEL_LOW [8:8]
/// No description
GPIO10_LEVEL_LOW: u1 = 0,
/// GPIO10_LEVEL_HIGH [9:9]
/// No description
GPIO10_LEVEL_HIGH: u1 = 0,
/// GPIO10_EDGE_LOW [10:10]
/// No description
GPIO10_EDGE_LOW: u1 = 0,
/// GPIO10_EDGE_HIGH [11:11]
/// No description
GPIO10_EDGE_HIGH: u1 = 0,
/// GPIO11_LEVEL_LOW [12:12]
/// No description
GPIO11_LEVEL_LOW: u1 = 0,
/// GPIO11_LEVEL_HIGH [13:13]
/// No description
GPIO11_LEVEL_HIGH: u1 = 0,
/// GPIO11_EDGE_LOW [14:14]
/// No description
GPIO11_EDGE_LOW: u1 = 0,
/// GPIO11_EDGE_HIGH [15:15]
/// No description
GPIO11_EDGE_HIGH: u1 = 0,
/// GPIO12_LEVEL_LOW [16:16]
/// No description
GPIO12_LEVEL_LOW: u1 = 0,
/// GPIO12_LEVEL_HIGH [17:17]
/// No description
GPIO12_LEVEL_HIGH: u1 = 0,
/// GPIO12_EDGE_LOW [18:18]
/// No description
GPIO12_EDGE_LOW: u1 = 0,
/// GPIO12_EDGE_HIGH [19:19]
/// No description
GPIO12_EDGE_HIGH: u1 = 0,
/// GPIO13_LEVEL_LOW [20:20]
/// No description
GPIO13_LEVEL_LOW: u1 = 0,
/// GPIO13_LEVEL_HIGH [21:21]
/// No description
GPIO13_LEVEL_HIGH: u1 = 0,
/// GPIO13_EDGE_LOW [22:22]
/// No description
GPIO13_EDGE_LOW: u1 = 0,
/// GPIO13_EDGE_HIGH [23:23]
/// No description
GPIO13_EDGE_HIGH: u1 = 0,
/// GPIO14_LEVEL_LOW [24:24]
/// No description
GPIO14_LEVEL_LOW: u1 = 0,
/// GPIO14_LEVEL_HIGH [25:25]
/// No description
GPIO14_LEVEL_HIGH: u1 = 0,
/// GPIO14_EDGE_LOW [26:26]
/// No description
GPIO14_EDGE_LOW: u1 = 0,
/// GPIO14_EDGE_HIGH [27:27]
/// No description
GPIO14_EDGE_HIGH: u1 = 0,
/// GPIO15_LEVEL_LOW [28:28]
/// No description
GPIO15_LEVEL_LOW: u1 = 0,
/// GPIO15_LEVEL_HIGH [29:29]
/// No description
GPIO15_LEVEL_HIGH: u1 = 0,
/// GPIO15_EDGE_LOW [30:30]
/// No description
GPIO15_EDGE_LOW: u1 = 0,
/// GPIO15_EDGE_HIGH [31:31]
/// No description
GPIO15_EDGE_HIGH: u1 = 0,
};
/// Interrupt Force for dormant_wake
pub const DORMANT_WAKE_INTF1 = Register(DORMANT_WAKE_INTF1_val).init(base_address + 0x174);

/// DORMANT_WAKE_INTF0
const DORMANT_WAKE_INTF0_val = packed struct {
/// GPIO0_LEVEL_LOW [0:0]
/// No description
GPIO0_LEVEL_LOW: u1 = 0,
/// GPIO0_LEVEL_HIGH [1:1]
/// No description
GPIO0_LEVEL_HIGH: u1 = 0,
/// GPIO0_EDGE_LOW [2:2]
/// No description
GPIO0_EDGE_LOW: u1 = 0,
/// GPIO0_EDGE_HIGH [3:3]
/// No description
GPIO0_EDGE_HIGH: u1 = 0,
/// GPIO1_LEVEL_LOW [4:4]
/// No description
GPIO1_LEVEL_LOW: u1 = 0,
/// GPIO1_LEVEL_HIGH [5:5]
/// No description
GPIO1_LEVEL_HIGH: u1 = 0,
/// GPIO1_EDGE_LOW [6:6]
/// No description
GPIO1_EDGE_LOW: u1 = 0,
/// GPIO1_EDGE_HIGH [7:7]
/// No description
GPIO1_EDGE_HIGH: u1 = 0,
/// GPIO2_LEVEL_LOW [8:8]
/// No description
GPIO2_LEVEL_LOW: u1 = 0,
/// GPIO2_LEVEL_HIGH [9:9]
/// No description
GPIO2_LEVEL_HIGH: u1 = 0,
/// GPIO2_EDGE_LOW [10:10]
/// No description
GPIO2_EDGE_LOW: u1 = 0,
/// GPIO2_EDGE_HIGH [11:11]
/// No description
GPIO2_EDGE_HIGH: u1 = 0,
/// GPIO3_LEVEL_LOW [12:12]
/// No description
GPIO3_LEVEL_LOW: u1 = 0,
/// GPIO3_LEVEL_HIGH [13:13]
/// No description
GPIO3_LEVEL_HIGH: u1 = 0,
/// GPIO3_EDGE_LOW [14:14]
/// No description
GPIO3_EDGE_LOW: u1 = 0,
/// GPIO3_EDGE_HIGH [15:15]
/// No description
GPIO3_EDGE_HIGH: u1 = 0,
/// GPIO4_LEVEL_LOW [16:16]
/// No description
GPIO4_LEVEL_LOW: u1 = 0,
/// GPIO4_LEVEL_HIGH [17:17]
/// No description
GPIO4_LEVEL_HIGH: u1 = 0,
/// GPIO4_EDGE_LOW [18:18]
/// No description
GPIO4_EDGE_LOW: u1 = 0,
/// GPIO4_EDGE_HIGH [19:19]
/// No description
GPIO4_EDGE_HIGH: u1 = 0,
/// GPIO5_LEVEL_LOW [20:20]
/// No description
GPIO5_LEVEL_LOW: u1 = 0,
/// GPIO5_LEVEL_HIGH [21:21]
/// No description
GPIO5_LEVEL_HIGH: u1 = 0,
/// GPIO5_EDGE_LOW [22:22]
/// No description
GPIO5_EDGE_LOW: u1 = 0,
/// GPIO5_EDGE_HIGH [23:23]
/// No description
GPIO5_EDGE_HIGH: u1 = 0,
/// GPIO6_LEVEL_LOW [24:24]
/// No description
GPIO6_LEVEL_LOW: u1 = 0,
/// GPIO6_LEVEL_HIGH [25:25]
/// No description
GPIO6_LEVEL_HIGH: u1 = 0,
/// GPIO6_EDGE_LOW [26:26]
/// No description
GPIO6_EDGE_LOW: u1 = 0,
/// GPIO6_EDGE_HIGH [27:27]
/// No description
GPIO6_EDGE_HIGH: u1 = 0,
/// GPIO7_LEVEL_LOW [28:28]
/// No description
GPIO7_LEVEL_LOW: u1 = 0,
/// GPIO7_LEVEL_HIGH [29:29]
/// No description
GPIO7_LEVEL_HIGH: u1 = 0,
/// GPIO7_EDGE_LOW [30:30]
/// No description
GPIO7_EDGE_LOW: u1 = 0,
/// GPIO7_EDGE_HIGH [31:31]
/// No description
GPIO7_EDGE_HIGH: u1 = 0,
};
/// Interrupt Force for dormant_wake
pub const DORMANT_WAKE_INTF0 = Register(DORMANT_WAKE_INTF0_val).init(base_address + 0x170);

/// DORMANT_WAKE_INTE3
const DORMANT_WAKE_INTE3_val = packed struct {
/// GPIO24_LEVEL_LOW [0:0]
/// No description
GPIO24_LEVEL_LOW: u1 = 0,
/// GPIO24_LEVEL_HIGH [1:1]
/// No description
GPIO24_LEVEL_HIGH: u1 = 0,
/// GPIO24_EDGE_LOW [2:2]
/// No description
GPIO24_EDGE_LOW: u1 = 0,
/// GPIO24_EDGE_HIGH [3:3]
/// No description
GPIO24_EDGE_HIGH: u1 = 0,
/// GPIO25_LEVEL_LOW [4:4]
/// No description
GPIO25_LEVEL_LOW: u1 = 0,
/// GPIO25_LEVEL_HIGH [5:5]
/// No description
GPIO25_LEVEL_HIGH: u1 = 0,
/// GPIO25_EDGE_LOW [6:6]
/// No description
GPIO25_EDGE_LOW: u1 = 0,
/// GPIO25_EDGE_HIGH [7:7]
/// No description
GPIO25_EDGE_HIGH: u1 = 0,
/// GPIO26_LEVEL_LOW [8:8]
/// No description
GPIO26_LEVEL_LOW: u1 = 0,
/// GPIO26_LEVEL_HIGH [9:9]
/// No description
GPIO26_LEVEL_HIGH: u1 = 0,
/// GPIO26_EDGE_LOW [10:10]
/// No description
GPIO26_EDGE_LOW: u1 = 0,
/// GPIO26_EDGE_HIGH [11:11]
/// No description
GPIO26_EDGE_HIGH: u1 = 0,
/// GPIO27_LEVEL_LOW [12:12]
/// No description
GPIO27_LEVEL_LOW: u1 = 0,
/// GPIO27_LEVEL_HIGH [13:13]
/// No description
GPIO27_LEVEL_HIGH: u1 = 0,
/// GPIO27_EDGE_LOW [14:14]
/// No description
GPIO27_EDGE_LOW: u1 = 0,
/// GPIO27_EDGE_HIGH [15:15]
/// No description
GPIO27_EDGE_HIGH: u1 = 0,
/// GPIO28_LEVEL_LOW [16:16]
/// No description
GPIO28_LEVEL_LOW: u1 = 0,
/// GPIO28_LEVEL_HIGH [17:17]
/// No description
GPIO28_LEVEL_HIGH: u1 = 0,
/// GPIO28_EDGE_LOW [18:18]
/// No description
GPIO28_EDGE_LOW: u1 = 0,
/// GPIO28_EDGE_HIGH [19:19]
/// No description
GPIO28_EDGE_HIGH: u1 = 0,
/// GPIO29_LEVEL_LOW [20:20]
/// No description
GPIO29_LEVEL_LOW: u1 = 0,
/// GPIO29_LEVEL_HIGH [21:21]
/// No description
GPIO29_LEVEL_HIGH: u1 = 0,
/// GPIO29_EDGE_LOW [22:22]
/// No description
GPIO29_EDGE_LOW: u1 = 0,
/// GPIO29_EDGE_HIGH [23:23]
/// No description
GPIO29_EDGE_HIGH: u1 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// Interrupt Enable for dormant_wake
pub const DORMANT_WAKE_INTE3 = Register(DORMANT_WAKE_INTE3_val).init(base_address + 0x16c);

/// DORMANT_WAKE_INTE2
const DORMANT_WAKE_INTE2_val = packed struct {
/// GPIO16_LEVEL_LOW [0:0]
/// No description
GPIO16_LEVEL_LOW: u1 = 0,
/// GPIO16_LEVEL_HIGH [1:1]
/// No description
GPIO16_LEVEL_HIGH: u1 = 0,
/// GPIO16_EDGE_LOW [2:2]
/// No description
GPIO16_EDGE_LOW: u1 = 0,
/// GPIO16_EDGE_HIGH [3:3]
/// No description
GPIO16_EDGE_HIGH: u1 = 0,
/// GPIO17_LEVEL_LOW [4:4]
/// No description
GPIO17_LEVEL_LOW: u1 = 0,
/// GPIO17_LEVEL_HIGH [5:5]
/// No description
GPIO17_LEVEL_HIGH: u1 = 0,
/// GPIO17_EDGE_LOW [6:6]
/// No description
GPIO17_EDGE_LOW: u1 = 0,
/// GPIO17_EDGE_HIGH [7:7]
/// No description
GPIO17_EDGE_HIGH: u1 = 0,
/// GPIO18_LEVEL_LOW [8:8]
/// No description
GPIO18_LEVEL_LOW: u1 = 0,
/// GPIO18_LEVEL_HIGH [9:9]
/// No description
GPIO18_LEVEL_HIGH: u1 = 0,
/// GPIO18_EDGE_LOW [10:10]
/// No description
GPIO18_EDGE_LOW: u1 = 0,
/// GPIO18_EDGE_HIGH [11:11]
/// No description
GPIO18_EDGE_HIGH: u1 = 0,
/// GPIO19_LEVEL_LOW [12:12]
/// No description
GPIO19_LEVEL_LOW: u1 = 0,
/// GPIO19_LEVEL_HIGH [13:13]
/// No description
GPIO19_LEVEL_HIGH: u1 = 0,
/// GPIO19_EDGE_LOW [14:14]
/// No description
GPIO19_EDGE_LOW: u1 = 0,
/// GPIO19_EDGE_HIGH [15:15]
/// No description
GPIO19_EDGE_HIGH: u1 = 0,
/// GPIO20_LEVEL_LOW [16:16]
/// No description
GPIO20_LEVEL_LOW: u1 = 0,
/// GPIO20_LEVEL_HIGH [17:17]
/// No description
GPIO20_LEVEL_HIGH: u1 = 0,
/// GPIO20_EDGE_LOW [18:18]
/// No description
GPIO20_EDGE_LOW: u1 = 0,
/// GPIO20_EDGE_HIGH [19:19]
/// No description
GPIO20_EDGE_HIGH: u1 = 0,
/// GPIO21_LEVEL_LOW [20:20]
/// No description
GPIO21_LEVEL_LOW: u1 = 0,
/// GPIO21_LEVEL_HIGH [21:21]
/// No description
GPIO21_LEVEL_HIGH: u1 = 0,
/// GPIO21_EDGE_LOW [22:22]
/// No description
GPIO21_EDGE_LOW: u1 = 0,
/// GPIO21_EDGE_HIGH [23:23]
/// No description
GPIO21_EDGE_HIGH: u1 = 0,
/// GPIO22_LEVEL_LOW [24:24]
/// No description
GPIO22_LEVEL_LOW: u1 = 0,
/// GPIO22_LEVEL_HIGH [25:25]
/// No description
GPIO22_LEVEL_HIGH: u1 = 0,
/// GPIO22_EDGE_LOW [26:26]
/// No description
GPIO22_EDGE_LOW: u1 = 0,
/// GPIO22_EDGE_HIGH [27:27]
/// No description
GPIO22_EDGE_HIGH: u1 = 0,
/// GPIO23_LEVEL_LOW [28:28]
/// No description
GPIO23_LEVEL_LOW: u1 = 0,
/// GPIO23_LEVEL_HIGH [29:29]
/// No description
GPIO23_LEVEL_HIGH: u1 = 0,
/// GPIO23_EDGE_LOW [30:30]
/// No description
GPIO23_EDGE_LOW: u1 = 0,
/// GPIO23_EDGE_HIGH [31:31]
/// No description
GPIO23_EDGE_HIGH: u1 = 0,
};
/// Interrupt Enable for dormant_wake
pub const DORMANT_WAKE_INTE2 = Register(DORMANT_WAKE_INTE2_val).init(base_address + 0x168);

/// DORMANT_WAKE_INTE1
const DORMANT_WAKE_INTE1_val = packed struct {
/// GPIO8_LEVEL_LOW [0:0]
/// No description
GPIO8_LEVEL_LOW: u1 = 0,
/// GPIO8_LEVEL_HIGH [1:1]
/// No description
GPIO8_LEVEL_HIGH: u1 = 0,
/// GPIO8_EDGE_LOW [2:2]
/// No description
GPIO8_EDGE_LOW: u1 = 0,
/// GPIO8_EDGE_HIGH [3:3]
/// No description
GPIO8_EDGE_HIGH: u1 = 0,
/// GPIO9_LEVEL_LOW [4:4]
/// No description
GPIO9_LEVEL_LOW: u1 = 0,
/// GPIO9_LEVEL_HIGH [5:5]
/// No description
GPIO9_LEVEL_HIGH: u1 = 0,
/// GPIO9_EDGE_LOW [6:6]
/// No description
GPIO9_EDGE_LOW: u1 = 0,
/// GPIO9_EDGE_HIGH [7:7]
/// No description
GPIO9_EDGE_HIGH: u1 = 0,
/// GPIO10_LEVEL_LOW [8:8]
/// No description
GPIO10_LEVEL_LOW: u1 = 0,
/// GPIO10_LEVEL_HIGH [9:9]
/// No description
GPIO10_LEVEL_HIGH: u1 = 0,
/// GPIO10_EDGE_LOW [10:10]
/// No description
GPIO10_EDGE_LOW: u1 = 0,
/// GPIO10_EDGE_HIGH [11:11]
/// No description
GPIO10_EDGE_HIGH: u1 = 0,
/// GPIO11_LEVEL_LOW [12:12]
/// No description
GPIO11_LEVEL_LOW: u1 = 0,
/// GPIO11_LEVEL_HIGH [13:13]
/// No description
GPIO11_LEVEL_HIGH: u1 = 0,
/// GPIO11_EDGE_LOW [14:14]
/// No description
GPIO11_EDGE_LOW: u1 = 0,
/// GPIO11_EDGE_HIGH [15:15]
/// No description
GPIO11_EDGE_HIGH: u1 = 0,
/// GPIO12_LEVEL_LOW [16:16]
/// No description
GPIO12_LEVEL_LOW: u1 = 0,
/// GPIO12_LEVEL_HIGH [17:17]
/// No description
GPIO12_LEVEL_HIGH: u1 = 0,
/// GPIO12_EDGE_LOW [18:18]
/// No description
GPIO12_EDGE_LOW: u1 = 0,
/// GPIO12_EDGE_HIGH [19:19]
/// No description
GPIO12_EDGE_HIGH: u1 = 0,
/// GPIO13_LEVEL_LOW [20:20]
/// No description
GPIO13_LEVEL_LOW: u1 = 0,
/// GPIO13_LEVEL_HIGH [21:21]
/// No description
GPIO13_LEVEL_HIGH: u1 = 0,
/// GPIO13_EDGE_LOW [22:22]
/// No description
GPIO13_EDGE_LOW: u1 = 0,
/// GPIO13_EDGE_HIGH [23:23]
/// No description
GPIO13_EDGE_HIGH: u1 = 0,
/// GPIO14_LEVEL_LOW [24:24]
/// No description
GPIO14_LEVEL_LOW: u1 = 0,
/// GPIO14_LEVEL_HIGH [25:25]
/// No description
GPIO14_LEVEL_HIGH: u1 = 0,
/// GPIO14_EDGE_LOW [26:26]
/// No description
GPIO14_EDGE_LOW: u1 = 0,
/// GPIO14_EDGE_HIGH [27:27]
/// No description
GPIO14_EDGE_HIGH: u1 = 0,
/// GPIO15_LEVEL_LOW [28:28]
/// No description
GPIO15_LEVEL_LOW: u1 = 0,
/// GPIO15_LEVEL_HIGH [29:29]
/// No description
GPIO15_LEVEL_HIGH: u1 = 0,
/// GPIO15_EDGE_LOW [30:30]
/// No description
GPIO15_EDGE_LOW: u1 = 0,
/// GPIO15_EDGE_HIGH [31:31]
/// No description
GPIO15_EDGE_HIGH: u1 = 0,
};
/// Interrupt Enable for dormant_wake
pub const DORMANT_WAKE_INTE1 = Register(DORMANT_WAKE_INTE1_val).init(base_address + 0x164);

/// DORMANT_WAKE_INTE0
const DORMANT_WAKE_INTE0_val = packed struct {
/// GPIO0_LEVEL_LOW [0:0]
/// No description
GPIO0_LEVEL_LOW: u1 = 0,
/// GPIO0_LEVEL_HIGH [1:1]
/// No description
GPIO0_LEVEL_HIGH: u1 = 0,
/// GPIO0_EDGE_LOW [2:2]
/// No description
GPIO0_EDGE_LOW: u1 = 0,
/// GPIO0_EDGE_HIGH [3:3]
/// No description
GPIO0_EDGE_HIGH: u1 = 0,
/// GPIO1_LEVEL_LOW [4:4]
/// No description
GPIO1_LEVEL_LOW: u1 = 0,
/// GPIO1_LEVEL_HIGH [5:5]
/// No description
GPIO1_LEVEL_HIGH: u1 = 0,
/// GPIO1_EDGE_LOW [6:6]
/// No description
GPIO1_EDGE_LOW: u1 = 0,
/// GPIO1_EDGE_HIGH [7:7]
/// No description
GPIO1_EDGE_HIGH: u1 = 0,
/// GPIO2_LEVEL_LOW [8:8]
/// No description
GPIO2_LEVEL_LOW: u1 = 0,
/// GPIO2_LEVEL_HIGH [9:9]
/// No description
GPIO2_LEVEL_HIGH: u1 = 0,
/// GPIO2_EDGE_LOW [10:10]
/// No description
GPIO2_EDGE_LOW: u1 = 0,
/// GPIO2_EDGE_HIGH [11:11]
/// No description
GPIO2_EDGE_HIGH: u1 = 0,
/// GPIO3_LEVEL_LOW [12:12]
/// No description
GPIO3_LEVEL_LOW: u1 = 0,
/// GPIO3_LEVEL_HIGH [13:13]
/// No description
GPIO3_LEVEL_HIGH: u1 = 0,
/// GPIO3_EDGE_LOW [14:14]
/// No description
GPIO3_EDGE_LOW: u1 = 0,
/// GPIO3_EDGE_HIGH [15:15]
/// No description
GPIO3_EDGE_HIGH: u1 = 0,
/// GPIO4_LEVEL_LOW [16:16]
/// No description
GPIO4_LEVEL_LOW: u1 = 0,
/// GPIO4_LEVEL_HIGH [17:17]
/// No description
GPIO4_LEVEL_HIGH: u1 = 0,
/// GPIO4_EDGE_LOW [18:18]
/// No description
GPIO4_EDGE_LOW: u1 = 0,
/// GPIO4_EDGE_HIGH [19:19]
/// No description
GPIO4_EDGE_HIGH: u1 = 0,
/// GPIO5_LEVEL_LOW [20:20]
/// No description
GPIO5_LEVEL_LOW: u1 = 0,
/// GPIO5_LEVEL_HIGH [21:21]
/// No description
GPIO5_LEVEL_HIGH: u1 = 0,
/// GPIO5_EDGE_LOW [22:22]
/// No description
GPIO5_EDGE_LOW: u1 = 0,
/// GPIO5_EDGE_HIGH [23:23]
/// No description
GPIO5_EDGE_HIGH: u1 = 0,
/// GPIO6_LEVEL_LOW [24:24]
/// No description
GPIO6_LEVEL_LOW: u1 = 0,
/// GPIO6_LEVEL_HIGH [25:25]
/// No description
GPIO6_LEVEL_HIGH: u1 = 0,
/// GPIO6_EDGE_LOW [26:26]
/// No description
GPIO6_EDGE_LOW: u1 = 0,
/// GPIO6_EDGE_HIGH [27:27]
/// No description
GPIO6_EDGE_HIGH: u1 = 0,
/// GPIO7_LEVEL_LOW [28:28]
/// No description
GPIO7_LEVEL_LOW: u1 = 0,
/// GPIO7_LEVEL_HIGH [29:29]
/// No description
GPIO7_LEVEL_HIGH: u1 = 0,
/// GPIO7_EDGE_LOW [30:30]
/// No description
GPIO7_EDGE_LOW: u1 = 0,
/// GPIO7_EDGE_HIGH [31:31]
/// No description
GPIO7_EDGE_HIGH: u1 = 0,
};
/// Interrupt Enable for dormant_wake
pub const DORMANT_WAKE_INTE0 = Register(DORMANT_WAKE_INTE0_val).init(base_address + 0x160);

/// PROC1_INTS3
const PROC1_INTS3_val = packed struct {
/// GPIO24_LEVEL_LOW [0:0]
/// No description
GPIO24_LEVEL_LOW: u1 = 0,
/// GPIO24_LEVEL_HIGH [1:1]
/// No description
GPIO24_LEVEL_HIGH: u1 = 0,
/// GPIO24_EDGE_LOW [2:2]
/// No description
GPIO24_EDGE_LOW: u1 = 0,
/// GPIO24_EDGE_HIGH [3:3]
/// No description
GPIO24_EDGE_HIGH: u1 = 0,
/// GPIO25_LEVEL_LOW [4:4]
/// No description
GPIO25_LEVEL_LOW: u1 = 0,
/// GPIO25_LEVEL_HIGH [5:5]
/// No description
GPIO25_LEVEL_HIGH: u1 = 0,
/// GPIO25_EDGE_LOW [6:6]
/// No description
GPIO25_EDGE_LOW: u1 = 0,
/// GPIO25_EDGE_HIGH [7:7]
/// No description
GPIO25_EDGE_HIGH: u1 = 0,
/// GPIO26_LEVEL_LOW [8:8]
/// No description
GPIO26_LEVEL_LOW: u1 = 0,
/// GPIO26_LEVEL_HIGH [9:9]
/// No description
GPIO26_LEVEL_HIGH: u1 = 0,
/// GPIO26_EDGE_LOW [10:10]
/// No description
GPIO26_EDGE_LOW: u1 = 0,
/// GPIO26_EDGE_HIGH [11:11]
/// No description
GPIO26_EDGE_HIGH: u1 = 0,
/// GPIO27_LEVEL_LOW [12:12]
/// No description
GPIO27_LEVEL_LOW: u1 = 0,
/// GPIO27_LEVEL_HIGH [13:13]
/// No description
GPIO27_LEVEL_HIGH: u1 = 0,
/// GPIO27_EDGE_LOW [14:14]
/// No description
GPIO27_EDGE_LOW: u1 = 0,
/// GPIO27_EDGE_HIGH [15:15]
/// No description
GPIO27_EDGE_HIGH: u1 = 0,
/// GPIO28_LEVEL_LOW [16:16]
/// No description
GPIO28_LEVEL_LOW: u1 = 0,
/// GPIO28_LEVEL_HIGH [17:17]
/// No description
GPIO28_LEVEL_HIGH: u1 = 0,
/// GPIO28_EDGE_LOW [18:18]
/// No description
GPIO28_EDGE_LOW: u1 = 0,
/// GPIO28_EDGE_HIGH [19:19]
/// No description
GPIO28_EDGE_HIGH: u1 = 0,
/// GPIO29_LEVEL_LOW [20:20]
/// No description
GPIO29_LEVEL_LOW: u1 = 0,
/// GPIO29_LEVEL_HIGH [21:21]
/// No description
GPIO29_LEVEL_HIGH: u1 = 0,
/// GPIO29_EDGE_LOW [22:22]
/// No description
GPIO29_EDGE_LOW: u1 = 0,
/// GPIO29_EDGE_HIGH [23:23]
/// No description
GPIO29_EDGE_HIGH: u1 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// Interrupt status after masking &amp; forcing for proc1
pub const PROC1_INTS3 = Register(PROC1_INTS3_val).init(base_address + 0x15c);

/// PROC1_INTS2
const PROC1_INTS2_val = packed struct {
/// GPIO16_LEVEL_LOW [0:0]
/// No description
GPIO16_LEVEL_LOW: u1 = 0,
/// GPIO16_LEVEL_HIGH [1:1]
/// No description
GPIO16_LEVEL_HIGH: u1 = 0,
/// GPIO16_EDGE_LOW [2:2]
/// No description
GPIO16_EDGE_LOW: u1 = 0,
/// GPIO16_EDGE_HIGH [3:3]
/// No description
GPIO16_EDGE_HIGH: u1 = 0,
/// GPIO17_LEVEL_LOW [4:4]
/// No description
GPIO17_LEVEL_LOW: u1 = 0,
/// GPIO17_LEVEL_HIGH [5:5]
/// No description
GPIO17_LEVEL_HIGH: u1 = 0,
/// GPIO17_EDGE_LOW [6:6]
/// No description
GPIO17_EDGE_LOW: u1 = 0,
/// GPIO17_EDGE_HIGH [7:7]
/// No description
GPIO17_EDGE_HIGH: u1 = 0,
/// GPIO18_LEVEL_LOW [8:8]
/// No description
GPIO18_LEVEL_LOW: u1 = 0,
/// GPIO18_LEVEL_HIGH [9:9]
/// No description
GPIO18_LEVEL_HIGH: u1 = 0,
/// GPIO18_EDGE_LOW [10:10]
/// No description
GPIO18_EDGE_LOW: u1 = 0,
/// GPIO18_EDGE_HIGH [11:11]
/// No description
GPIO18_EDGE_HIGH: u1 = 0,
/// GPIO19_LEVEL_LOW [12:12]
/// No description
GPIO19_LEVEL_LOW: u1 = 0,
/// GPIO19_LEVEL_HIGH [13:13]
/// No description
GPIO19_LEVEL_HIGH: u1 = 0,
/// GPIO19_EDGE_LOW [14:14]
/// No description
GPIO19_EDGE_LOW: u1 = 0,
/// GPIO19_EDGE_HIGH [15:15]
/// No description
GPIO19_EDGE_HIGH: u1 = 0,
/// GPIO20_LEVEL_LOW [16:16]
/// No description
GPIO20_LEVEL_LOW: u1 = 0,
/// GPIO20_LEVEL_HIGH [17:17]
/// No description
GPIO20_LEVEL_HIGH: u1 = 0,
/// GPIO20_EDGE_LOW [18:18]
/// No description
GPIO20_EDGE_LOW: u1 = 0,
/// GPIO20_EDGE_HIGH [19:19]
/// No description
GPIO20_EDGE_HIGH: u1 = 0,
/// GPIO21_LEVEL_LOW [20:20]
/// No description
GPIO21_LEVEL_LOW: u1 = 0,
/// GPIO21_LEVEL_HIGH [21:21]
/// No description
GPIO21_LEVEL_HIGH: u1 = 0,
/// GPIO21_EDGE_LOW [22:22]
/// No description
GPIO21_EDGE_LOW: u1 = 0,
/// GPIO21_EDGE_HIGH [23:23]
/// No description
GPIO21_EDGE_HIGH: u1 = 0,
/// GPIO22_LEVEL_LOW [24:24]
/// No description
GPIO22_LEVEL_LOW: u1 = 0,
/// GPIO22_LEVEL_HIGH [25:25]
/// No description
GPIO22_LEVEL_HIGH: u1 = 0,
/// GPIO22_EDGE_LOW [26:26]
/// No description
GPIO22_EDGE_LOW: u1 = 0,
/// GPIO22_EDGE_HIGH [27:27]
/// No description
GPIO22_EDGE_HIGH: u1 = 0,
/// GPIO23_LEVEL_LOW [28:28]
/// No description
GPIO23_LEVEL_LOW: u1 = 0,
/// GPIO23_LEVEL_HIGH [29:29]
/// No description
GPIO23_LEVEL_HIGH: u1 = 0,
/// GPIO23_EDGE_LOW [30:30]
/// No description
GPIO23_EDGE_LOW: u1 = 0,
/// GPIO23_EDGE_HIGH [31:31]
/// No description
GPIO23_EDGE_HIGH: u1 = 0,
};
/// Interrupt status after masking &amp; forcing for proc1
pub const PROC1_INTS2 = Register(PROC1_INTS2_val).init(base_address + 0x158);

/// PROC1_INTS1
const PROC1_INTS1_val = packed struct {
/// GPIO8_LEVEL_LOW [0:0]
/// No description
GPIO8_LEVEL_LOW: u1 = 0,
/// GPIO8_LEVEL_HIGH [1:1]
/// No description
GPIO8_LEVEL_HIGH: u1 = 0,
/// GPIO8_EDGE_LOW [2:2]
/// No description
GPIO8_EDGE_LOW: u1 = 0,
/// GPIO8_EDGE_HIGH [3:3]
/// No description
GPIO8_EDGE_HIGH: u1 = 0,
/// GPIO9_LEVEL_LOW [4:4]
/// No description
GPIO9_LEVEL_LOW: u1 = 0,
/// GPIO9_LEVEL_HIGH [5:5]
/// No description
GPIO9_LEVEL_HIGH: u1 = 0,
/// GPIO9_EDGE_LOW [6:6]
/// No description
GPIO9_EDGE_LOW: u1 = 0,
/// GPIO9_EDGE_HIGH [7:7]
/// No description
GPIO9_EDGE_HIGH: u1 = 0,
/// GPIO10_LEVEL_LOW [8:8]
/// No description
GPIO10_LEVEL_LOW: u1 = 0,
/// GPIO10_LEVEL_HIGH [9:9]
/// No description
GPIO10_LEVEL_HIGH: u1 = 0,
/// GPIO10_EDGE_LOW [10:10]
/// No description
GPIO10_EDGE_LOW: u1 = 0,
/// GPIO10_EDGE_HIGH [11:11]
/// No description
GPIO10_EDGE_HIGH: u1 = 0,
/// GPIO11_LEVEL_LOW [12:12]
/// No description
GPIO11_LEVEL_LOW: u1 = 0,
/// GPIO11_LEVEL_HIGH [13:13]
/// No description
GPIO11_LEVEL_HIGH: u1 = 0,
/// GPIO11_EDGE_LOW [14:14]
/// No description
GPIO11_EDGE_LOW: u1 = 0,
/// GPIO11_EDGE_HIGH [15:15]
/// No description
GPIO11_EDGE_HIGH: u1 = 0,
/// GPIO12_LEVEL_LOW [16:16]
/// No description
GPIO12_LEVEL_LOW: u1 = 0,
/// GPIO12_LEVEL_HIGH [17:17]
/// No description
GPIO12_LEVEL_HIGH: u1 = 0,
/// GPIO12_EDGE_LOW [18:18]
/// No description
GPIO12_EDGE_LOW: u1 = 0,
/// GPIO12_EDGE_HIGH [19:19]
/// No description
GPIO12_EDGE_HIGH: u1 = 0,
/// GPIO13_LEVEL_LOW [20:20]
/// No description
GPIO13_LEVEL_LOW: u1 = 0,
/// GPIO13_LEVEL_HIGH [21:21]
/// No description
GPIO13_LEVEL_HIGH: u1 = 0,
/// GPIO13_EDGE_LOW [22:22]
/// No description
GPIO13_EDGE_LOW: u1 = 0,
/// GPIO13_EDGE_HIGH [23:23]
/// No description
GPIO13_EDGE_HIGH: u1 = 0,
/// GPIO14_LEVEL_LOW [24:24]
/// No description
GPIO14_LEVEL_LOW: u1 = 0,
/// GPIO14_LEVEL_HIGH [25:25]
/// No description
GPIO14_LEVEL_HIGH: u1 = 0,
/// GPIO14_EDGE_LOW [26:26]
/// No description
GPIO14_EDGE_LOW: u1 = 0,
/// GPIO14_EDGE_HIGH [27:27]
/// No description
GPIO14_EDGE_HIGH: u1 = 0,
/// GPIO15_LEVEL_LOW [28:28]
/// No description
GPIO15_LEVEL_LOW: u1 = 0,
/// GPIO15_LEVEL_HIGH [29:29]
/// No description
GPIO15_LEVEL_HIGH: u1 = 0,
/// GPIO15_EDGE_LOW [30:30]
/// No description
GPIO15_EDGE_LOW: u1 = 0,
/// GPIO15_EDGE_HIGH [31:31]
/// No description
GPIO15_EDGE_HIGH: u1 = 0,
};
/// Interrupt status after masking &amp; forcing for proc1
pub const PROC1_INTS1 = Register(PROC1_INTS1_val).init(base_address + 0x154);

/// PROC1_INTS0
const PROC1_INTS0_val = packed struct {
/// GPIO0_LEVEL_LOW [0:0]
/// No description
GPIO0_LEVEL_LOW: u1 = 0,
/// GPIO0_LEVEL_HIGH [1:1]
/// No description
GPIO0_LEVEL_HIGH: u1 = 0,
/// GPIO0_EDGE_LOW [2:2]
/// No description
GPIO0_EDGE_LOW: u1 = 0,
/// GPIO0_EDGE_HIGH [3:3]
/// No description
GPIO0_EDGE_HIGH: u1 = 0,
/// GPIO1_LEVEL_LOW [4:4]
/// No description
GPIO1_LEVEL_LOW: u1 = 0,
/// GPIO1_LEVEL_HIGH [5:5]
/// No description
GPIO1_LEVEL_HIGH: u1 = 0,
/// GPIO1_EDGE_LOW [6:6]
/// No description
GPIO1_EDGE_LOW: u1 = 0,
/// GPIO1_EDGE_HIGH [7:7]
/// No description
GPIO1_EDGE_HIGH: u1 = 0,
/// GPIO2_LEVEL_LOW [8:8]
/// No description
GPIO2_LEVEL_LOW: u1 = 0,
/// GPIO2_LEVEL_HIGH [9:9]
/// No description
GPIO2_LEVEL_HIGH: u1 = 0,
/// GPIO2_EDGE_LOW [10:10]
/// No description
GPIO2_EDGE_LOW: u1 = 0,
/// GPIO2_EDGE_HIGH [11:11]
/// No description
GPIO2_EDGE_HIGH: u1 = 0,
/// GPIO3_LEVEL_LOW [12:12]
/// No description
GPIO3_LEVEL_LOW: u1 = 0,
/// GPIO3_LEVEL_HIGH [13:13]
/// No description
GPIO3_LEVEL_HIGH: u1 = 0,
/// GPIO3_EDGE_LOW [14:14]
/// No description
GPIO3_EDGE_LOW: u1 = 0,
/// GPIO3_EDGE_HIGH [15:15]
/// No description
GPIO3_EDGE_HIGH: u1 = 0,
/// GPIO4_LEVEL_LOW [16:16]
/// No description
GPIO4_LEVEL_LOW: u1 = 0,
/// GPIO4_LEVEL_HIGH [17:17]
/// No description
GPIO4_LEVEL_HIGH: u1 = 0,
/// GPIO4_EDGE_LOW [18:18]
/// No description
GPIO4_EDGE_LOW: u1 = 0,
/// GPIO4_EDGE_HIGH [19:19]
/// No description
GPIO4_EDGE_HIGH: u1 = 0,
/// GPIO5_LEVEL_LOW [20:20]
/// No description
GPIO5_LEVEL_LOW: u1 = 0,
/// GPIO5_LEVEL_HIGH [21:21]
/// No description
GPIO5_LEVEL_HIGH: u1 = 0,
/// GPIO5_EDGE_LOW [22:22]
/// No description
GPIO5_EDGE_LOW: u1 = 0,
/// GPIO5_EDGE_HIGH [23:23]
/// No description
GPIO5_EDGE_HIGH: u1 = 0,
/// GPIO6_LEVEL_LOW [24:24]
/// No description
GPIO6_LEVEL_LOW: u1 = 0,
/// GPIO6_LEVEL_HIGH [25:25]
/// No description
GPIO6_LEVEL_HIGH: u1 = 0,
/// GPIO6_EDGE_LOW [26:26]
/// No description
GPIO6_EDGE_LOW: u1 = 0,
/// GPIO6_EDGE_HIGH [27:27]
/// No description
GPIO6_EDGE_HIGH: u1 = 0,
/// GPIO7_LEVEL_LOW [28:28]
/// No description
GPIO7_LEVEL_LOW: u1 = 0,
/// GPIO7_LEVEL_HIGH [29:29]
/// No description
GPIO7_LEVEL_HIGH: u1 = 0,
/// GPIO7_EDGE_LOW [30:30]
/// No description
GPIO7_EDGE_LOW: u1 = 0,
/// GPIO7_EDGE_HIGH [31:31]
/// No description
GPIO7_EDGE_HIGH: u1 = 0,
};
/// Interrupt status after masking &amp; forcing for proc1
pub const PROC1_INTS0 = Register(PROC1_INTS0_val).init(base_address + 0x150);

/// PROC1_INTF3
const PROC1_INTF3_val = packed struct {
/// GPIO24_LEVEL_LOW [0:0]
/// No description
GPIO24_LEVEL_LOW: u1 = 0,
/// GPIO24_LEVEL_HIGH [1:1]
/// No description
GPIO24_LEVEL_HIGH: u1 = 0,
/// GPIO24_EDGE_LOW [2:2]
/// No description
GPIO24_EDGE_LOW: u1 = 0,
/// GPIO24_EDGE_HIGH [3:3]
/// No description
GPIO24_EDGE_HIGH: u1 = 0,
/// GPIO25_LEVEL_LOW [4:4]
/// No description
GPIO25_LEVEL_LOW: u1 = 0,
/// GPIO25_LEVEL_HIGH [5:5]
/// No description
GPIO25_LEVEL_HIGH: u1 = 0,
/// GPIO25_EDGE_LOW [6:6]
/// No description
GPIO25_EDGE_LOW: u1 = 0,
/// GPIO25_EDGE_HIGH [7:7]
/// No description
GPIO25_EDGE_HIGH: u1 = 0,
/// GPIO26_LEVEL_LOW [8:8]
/// No description
GPIO26_LEVEL_LOW: u1 = 0,
/// GPIO26_LEVEL_HIGH [9:9]
/// No description
GPIO26_LEVEL_HIGH: u1 = 0,
/// GPIO26_EDGE_LOW [10:10]
/// No description
GPIO26_EDGE_LOW: u1 = 0,
/// GPIO26_EDGE_HIGH [11:11]
/// No description
GPIO26_EDGE_HIGH: u1 = 0,
/// GPIO27_LEVEL_LOW [12:12]
/// No description
GPIO27_LEVEL_LOW: u1 = 0,
/// GPIO27_LEVEL_HIGH [13:13]
/// No description
GPIO27_LEVEL_HIGH: u1 = 0,
/// GPIO27_EDGE_LOW [14:14]
/// No description
GPIO27_EDGE_LOW: u1 = 0,
/// GPIO27_EDGE_HIGH [15:15]
/// No description
GPIO27_EDGE_HIGH: u1 = 0,
/// GPIO28_LEVEL_LOW [16:16]
/// No description
GPIO28_LEVEL_LOW: u1 = 0,
/// GPIO28_LEVEL_HIGH [17:17]
/// No description
GPIO28_LEVEL_HIGH: u1 = 0,
/// GPIO28_EDGE_LOW [18:18]
/// No description
GPIO28_EDGE_LOW: u1 = 0,
/// GPIO28_EDGE_HIGH [19:19]
/// No description
GPIO28_EDGE_HIGH: u1 = 0,
/// GPIO29_LEVEL_LOW [20:20]
/// No description
GPIO29_LEVEL_LOW: u1 = 0,
/// GPIO29_LEVEL_HIGH [21:21]
/// No description
GPIO29_LEVEL_HIGH: u1 = 0,
/// GPIO29_EDGE_LOW [22:22]
/// No description
GPIO29_EDGE_LOW: u1 = 0,
/// GPIO29_EDGE_HIGH [23:23]
/// No description
GPIO29_EDGE_HIGH: u1 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// Interrupt Force for proc1
pub const PROC1_INTF3 = Register(PROC1_INTF3_val).init(base_address + 0x14c);

/// PROC1_INTF2
const PROC1_INTF2_val = packed struct {
/// GPIO16_LEVEL_LOW [0:0]
/// No description
GPIO16_LEVEL_LOW: u1 = 0,
/// GPIO16_LEVEL_HIGH [1:1]
/// No description
GPIO16_LEVEL_HIGH: u1 = 0,
/// GPIO16_EDGE_LOW [2:2]
/// No description
GPIO16_EDGE_LOW: u1 = 0,
/// GPIO16_EDGE_HIGH [3:3]
/// No description
GPIO16_EDGE_HIGH: u1 = 0,
/// GPIO17_LEVEL_LOW [4:4]
/// No description
GPIO17_LEVEL_LOW: u1 = 0,
/// GPIO17_LEVEL_HIGH [5:5]
/// No description
GPIO17_LEVEL_HIGH: u1 = 0,
/// GPIO17_EDGE_LOW [6:6]
/// No description
GPIO17_EDGE_LOW: u1 = 0,
/// GPIO17_EDGE_HIGH [7:7]
/// No description
GPIO17_EDGE_HIGH: u1 = 0,
/// GPIO18_LEVEL_LOW [8:8]
/// No description
GPIO18_LEVEL_LOW: u1 = 0,
/// GPIO18_LEVEL_HIGH [9:9]
/// No description
GPIO18_LEVEL_HIGH: u1 = 0,
/// GPIO18_EDGE_LOW [10:10]
/// No description
GPIO18_EDGE_LOW: u1 = 0,
/// GPIO18_EDGE_HIGH [11:11]
/// No description
GPIO18_EDGE_HIGH: u1 = 0,
/// GPIO19_LEVEL_LOW [12:12]
/// No description
GPIO19_LEVEL_LOW: u1 = 0,
/// GPIO19_LEVEL_HIGH [13:13]
/// No description
GPIO19_LEVEL_HIGH: u1 = 0,
/// GPIO19_EDGE_LOW [14:14]
/// No description
GPIO19_EDGE_LOW: u1 = 0,
/// GPIO19_EDGE_HIGH [15:15]
/// No description
GPIO19_EDGE_HIGH: u1 = 0,
/// GPIO20_LEVEL_LOW [16:16]
/// No description
GPIO20_LEVEL_LOW: u1 = 0,
/// GPIO20_LEVEL_HIGH [17:17]
/// No description
GPIO20_LEVEL_HIGH: u1 = 0,
/// GPIO20_EDGE_LOW [18:18]
/// No description
GPIO20_EDGE_LOW: u1 = 0,
/// GPIO20_EDGE_HIGH [19:19]
/// No description
GPIO20_EDGE_HIGH: u1 = 0,
/// GPIO21_LEVEL_LOW [20:20]
/// No description
GPIO21_LEVEL_LOW: u1 = 0,
/// GPIO21_LEVEL_HIGH [21:21]
/// No description
GPIO21_LEVEL_HIGH: u1 = 0,
/// GPIO21_EDGE_LOW [22:22]
/// No description
GPIO21_EDGE_LOW: u1 = 0,
/// GPIO21_EDGE_HIGH [23:23]
/// No description
GPIO21_EDGE_HIGH: u1 = 0,
/// GPIO22_LEVEL_LOW [24:24]
/// No description
GPIO22_LEVEL_LOW: u1 = 0,
/// GPIO22_LEVEL_HIGH [25:25]
/// No description
GPIO22_LEVEL_HIGH: u1 = 0,
/// GPIO22_EDGE_LOW [26:26]
/// No description
GPIO22_EDGE_LOW: u1 = 0,
/// GPIO22_EDGE_HIGH [27:27]
/// No description
GPIO22_EDGE_HIGH: u1 = 0,
/// GPIO23_LEVEL_LOW [28:28]
/// No description
GPIO23_LEVEL_LOW: u1 = 0,
/// GPIO23_LEVEL_HIGH [29:29]
/// No description
GPIO23_LEVEL_HIGH: u1 = 0,
/// GPIO23_EDGE_LOW [30:30]
/// No description
GPIO23_EDGE_LOW: u1 = 0,
/// GPIO23_EDGE_HIGH [31:31]
/// No description
GPIO23_EDGE_HIGH: u1 = 0,
};
/// Interrupt Force for proc1
pub const PROC1_INTF2 = Register(PROC1_INTF2_val).init(base_address + 0x148);

/// PROC1_INTF1
const PROC1_INTF1_val = packed struct {
/// GPIO8_LEVEL_LOW [0:0]
/// No description
GPIO8_LEVEL_LOW: u1 = 0,
/// GPIO8_LEVEL_HIGH [1:1]
/// No description
GPIO8_LEVEL_HIGH: u1 = 0,
/// GPIO8_EDGE_LOW [2:2]
/// No description
GPIO8_EDGE_LOW: u1 = 0,
/// GPIO8_EDGE_HIGH [3:3]
/// No description
GPIO8_EDGE_HIGH: u1 = 0,
/// GPIO9_LEVEL_LOW [4:4]
/// No description
GPIO9_LEVEL_LOW: u1 = 0,
/// GPIO9_LEVEL_HIGH [5:5]
/// No description
GPIO9_LEVEL_HIGH: u1 = 0,
/// GPIO9_EDGE_LOW [6:6]
/// No description
GPIO9_EDGE_LOW: u1 = 0,
/// GPIO9_EDGE_HIGH [7:7]
/// No description
GPIO9_EDGE_HIGH: u1 = 0,
/// GPIO10_LEVEL_LOW [8:8]
/// No description
GPIO10_LEVEL_LOW: u1 = 0,
/// GPIO10_LEVEL_HIGH [9:9]
/// No description
GPIO10_LEVEL_HIGH: u1 = 0,
/// GPIO10_EDGE_LOW [10:10]
/// No description
GPIO10_EDGE_LOW: u1 = 0,
/// GPIO10_EDGE_HIGH [11:11]
/// No description
GPIO10_EDGE_HIGH: u1 = 0,
/// GPIO11_LEVEL_LOW [12:12]
/// No description
GPIO11_LEVEL_LOW: u1 = 0,
/// GPIO11_LEVEL_HIGH [13:13]
/// No description
GPIO11_LEVEL_HIGH: u1 = 0,
/// GPIO11_EDGE_LOW [14:14]
/// No description
GPIO11_EDGE_LOW: u1 = 0,
/// GPIO11_EDGE_HIGH [15:15]
/// No description
GPIO11_EDGE_HIGH: u1 = 0,
/// GPIO12_LEVEL_LOW [16:16]
/// No description
GPIO12_LEVEL_LOW: u1 = 0,
/// GPIO12_LEVEL_HIGH [17:17]
/// No description
GPIO12_LEVEL_HIGH: u1 = 0,
/// GPIO12_EDGE_LOW [18:18]
/// No description
GPIO12_EDGE_LOW: u1 = 0,
/// GPIO12_EDGE_HIGH [19:19]
/// No description
GPIO12_EDGE_HIGH: u1 = 0,
/// GPIO13_LEVEL_LOW [20:20]
/// No description
GPIO13_LEVEL_LOW: u1 = 0,
/// GPIO13_LEVEL_HIGH [21:21]
/// No description
GPIO13_LEVEL_HIGH: u1 = 0,
/// GPIO13_EDGE_LOW [22:22]
/// No description
GPIO13_EDGE_LOW: u1 = 0,
/// GPIO13_EDGE_HIGH [23:23]
/// No description
GPIO13_EDGE_HIGH: u1 = 0,
/// GPIO14_LEVEL_LOW [24:24]
/// No description
GPIO14_LEVEL_LOW: u1 = 0,
/// GPIO14_LEVEL_HIGH [25:25]
/// No description
GPIO14_LEVEL_HIGH: u1 = 0,
/// GPIO14_EDGE_LOW [26:26]
/// No description
GPIO14_EDGE_LOW: u1 = 0,
/// GPIO14_EDGE_HIGH [27:27]
/// No description
GPIO14_EDGE_HIGH: u1 = 0,
/// GPIO15_LEVEL_LOW [28:28]
/// No description
GPIO15_LEVEL_LOW: u1 = 0,
/// GPIO15_LEVEL_HIGH [29:29]
/// No description
GPIO15_LEVEL_HIGH: u1 = 0,
/// GPIO15_EDGE_LOW [30:30]
/// No description
GPIO15_EDGE_LOW: u1 = 0,
/// GPIO15_EDGE_HIGH [31:31]
/// No description
GPIO15_EDGE_HIGH: u1 = 0,
};
/// Interrupt Force for proc1
pub const PROC1_INTF1 = Register(PROC1_INTF1_val).init(base_address + 0x144);

/// PROC1_INTF0
const PROC1_INTF0_val = packed struct {
/// GPIO0_LEVEL_LOW [0:0]
/// No description
GPIO0_LEVEL_LOW: u1 = 0,
/// GPIO0_LEVEL_HIGH [1:1]
/// No description
GPIO0_LEVEL_HIGH: u1 = 0,
/// GPIO0_EDGE_LOW [2:2]
/// No description
GPIO0_EDGE_LOW: u1 = 0,
/// GPIO0_EDGE_HIGH [3:3]
/// No description
GPIO0_EDGE_HIGH: u1 = 0,
/// GPIO1_LEVEL_LOW [4:4]
/// No description
GPIO1_LEVEL_LOW: u1 = 0,
/// GPIO1_LEVEL_HIGH [5:5]
/// No description
GPIO1_LEVEL_HIGH: u1 = 0,
/// GPIO1_EDGE_LOW [6:6]
/// No description
GPIO1_EDGE_LOW: u1 = 0,
/// GPIO1_EDGE_HIGH [7:7]
/// No description
GPIO1_EDGE_HIGH: u1 = 0,
/// GPIO2_LEVEL_LOW [8:8]
/// No description
GPIO2_LEVEL_LOW: u1 = 0,
/// GPIO2_LEVEL_HIGH [9:9]
/// No description
GPIO2_LEVEL_HIGH: u1 = 0,
/// GPIO2_EDGE_LOW [10:10]
/// No description
GPIO2_EDGE_LOW: u1 = 0,
/// GPIO2_EDGE_HIGH [11:11]
/// No description
GPIO2_EDGE_HIGH: u1 = 0,
/// GPIO3_LEVEL_LOW [12:12]
/// No description
GPIO3_LEVEL_LOW: u1 = 0,
/// GPIO3_LEVEL_HIGH [13:13]
/// No description
GPIO3_LEVEL_HIGH: u1 = 0,
/// GPIO3_EDGE_LOW [14:14]
/// No description
GPIO3_EDGE_LOW: u1 = 0,
/// GPIO3_EDGE_HIGH [15:15]
/// No description
GPIO3_EDGE_HIGH: u1 = 0,
/// GPIO4_LEVEL_LOW [16:16]
/// No description
GPIO4_LEVEL_LOW: u1 = 0,
/// GPIO4_LEVEL_HIGH [17:17]
/// No description
GPIO4_LEVEL_HIGH: u1 = 0,
/// GPIO4_EDGE_LOW [18:18]
/// No description
GPIO4_EDGE_LOW: u1 = 0,
/// GPIO4_EDGE_HIGH [19:19]
/// No description
GPIO4_EDGE_HIGH: u1 = 0,
/// GPIO5_LEVEL_LOW [20:20]
/// No description
GPIO5_LEVEL_LOW: u1 = 0,
/// GPIO5_LEVEL_HIGH [21:21]
/// No description
GPIO5_LEVEL_HIGH: u1 = 0,
/// GPIO5_EDGE_LOW [22:22]
/// No description
GPIO5_EDGE_LOW: u1 = 0,
/// GPIO5_EDGE_HIGH [23:23]
/// No description
GPIO5_EDGE_HIGH: u1 = 0,
/// GPIO6_LEVEL_LOW [24:24]
/// No description
GPIO6_LEVEL_LOW: u1 = 0,
/// GPIO6_LEVEL_HIGH [25:25]
/// No description
GPIO6_LEVEL_HIGH: u1 = 0,
/// GPIO6_EDGE_LOW [26:26]
/// No description
GPIO6_EDGE_LOW: u1 = 0,
/// GPIO6_EDGE_HIGH [27:27]
/// No description
GPIO6_EDGE_HIGH: u1 = 0,
/// GPIO7_LEVEL_LOW [28:28]
/// No description
GPIO7_LEVEL_LOW: u1 = 0,
/// GPIO7_LEVEL_HIGH [29:29]
/// No description
GPIO7_LEVEL_HIGH: u1 = 0,
/// GPIO7_EDGE_LOW [30:30]
/// No description
GPIO7_EDGE_LOW: u1 = 0,
/// GPIO7_EDGE_HIGH [31:31]
/// No description
GPIO7_EDGE_HIGH: u1 = 0,
};
/// Interrupt Force for proc1
pub const PROC1_INTF0 = Register(PROC1_INTF0_val).init(base_address + 0x140);

/// PROC1_INTE3
const PROC1_INTE3_val = packed struct {
/// GPIO24_LEVEL_LOW [0:0]
/// No description
GPIO24_LEVEL_LOW: u1 = 0,
/// GPIO24_LEVEL_HIGH [1:1]
/// No description
GPIO24_LEVEL_HIGH: u1 = 0,
/// GPIO24_EDGE_LOW [2:2]
/// No description
GPIO24_EDGE_LOW: u1 = 0,
/// GPIO24_EDGE_HIGH [3:3]
/// No description
GPIO24_EDGE_HIGH: u1 = 0,
/// GPIO25_LEVEL_LOW [4:4]
/// No description
GPIO25_LEVEL_LOW: u1 = 0,
/// GPIO25_LEVEL_HIGH [5:5]
/// No description
GPIO25_LEVEL_HIGH: u1 = 0,
/// GPIO25_EDGE_LOW [6:6]
/// No description
GPIO25_EDGE_LOW: u1 = 0,
/// GPIO25_EDGE_HIGH [7:7]
/// No description
GPIO25_EDGE_HIGH: u1 = 0,
/// GPIO26_LEVEL_LOW [8:8]
/// No description
GPIO26_LEVEL_LOW: u1 = 0,
/// GPIO26_LEVEL_HIGH [9:9]
/// No description
GPIO26_LEVEL_HIGH: u1 = 0,
/// GPIO26_EDGE_LOW [10:10]
/// No description
GPIO26_EDGE_LOW: u1 = 0,
/// GPIO26_EDGE_HIGH [11:11]
/// No description
GPIO26_EDGE_HIGH: u1 = 0,
/// GPIO27_LEVEL_LOW [12:12]
/// No description
GPIO27_LEVEL_LOW: u1 = 0,
/// GPIO27_LEVEL_HIGH [13:13]
/// No description
GPIO27_LEVEL_HIGH: u1 = 0,
/// GPIO27_EDGE_LOW [14:14]
/// No description
GPIO27_EDGE_LOW: u1 = 0,
/// GPIO27_EDGE_HIGH [15:15]
/// No description
GPIO27_EDGE_HIGH: u1 = 0,
/// GPIO28_LEVEL_LOW [16:16]
/// No description
GPIO28_LEVEL_LOW: u1 = 0,
/// GPIO28_LEVEL_HIGH [17:17]
/// No description
GPIO28_LEVEL_HIGH: u1 = 0,
/// GPIO28_EDGE_LOW [18:18]
/// No description
GPIO28_EDGE_LOW: u1 = 0,
/// GPIO28_EDGE_HIGH [19:19]
/// No description
GPIO28_EDGE_HIGH: u1 = 0,
/// GPIO29_LEVEL_LOW [20:20]
/// No description
GPIO29_LEVEL_LOW: u1 = 0,
/// GPIO29_LEVEL_HIGH [21:21]
/// No description
GPIO29_LEVEL_HIGH: u1 = 0,
/// GPIO29_EDGE_LOW [22:22]
/// No description
GPIO29_EDGE_LOW: u1 = 0,
/// GPIO29_EDGE_HIGH [23:23]
/// No description
GPIO29_EDGE_HIGH: u1 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// Interrupt Enable for proc1
pub const PROC1_INTE3 = Register(PROC1_INTE3_val).init(base_address + 0x13c);

/// PROC1_INTE2
const PROC1_INTE2_val = packed struct {
/// GPIO16_LEVEL_LOW [0:0]
/// No description
GPIO16_LEVEL_LOW: u1 = 0,
/// GPIO16_LEVEL_HIGH [1:1]
/// No description
GPIO16_LEVEL_HIGH: u1 = 0,
/// GPIO16_EDGE_LOW [2:2]
/// No description
GPIO16_EDGE_LOW: u1 = 0,
/// GPIO16_EDGE_HIGH [3:3]
/// No description
GPIO16_EDGE_HIGH: u1 = 0,
/// GPIO17_LEVEL_LOW [4:4]
/// No description
GPIO17_LEVEL_LOW: u1 = 0,
/// GPIO17_LEVEL_HIGH [5:5]
/// No description
GPIO17_LEVEL_HIGH: u1 = 0,
/// GPIO17_EDGE_LOW [6:6]
/// No description
GPIO17_EDGE_LOW: u1 = 0,
/// GPIO17_EDGE_HIGH [7:7]
/// No description
GPIO17_EDGE_HIGH: u1 = 0,
/// GPIO18_LEVEL_LOW [8:8]
/// No description
GPIO18_LEVEL_LOW: u1 = 0,
/// GPIO18_LEVEL_HIGH [9:9]
/// No description
GPIO18_LEVEL_HIGH: u1 = 0,
/// GPIO18_EDGE_LOW [10:10]
/// No description
GPIO18_EDGE_LOW: u1 = 0,
/// GPIO18_EDGE_HIGH [11:11]
/// No description
GPIO18_EDGE_HIGH: u1 = 0,
/// GPIO19_LEVEL_LOW [12:12]
/// No description
GPIO19_LEVEL_LOW: u1 = 0,
/// GPIO19_LEVEL_HIGH [13:13]
/// No description
GPIO19_LEVEL_HIGH: u1 = 0,
/// GPIO19_EDGE_LOW [14:14]
/// No description
GPIO19_EDGE_LOW: u1 = 0,
/// GPIO19_EDGE_HIGH [15:15]
/// No description
GPIO19_EDGE_HIGH: u1 = 0,
/// GPIO20_LEVEL_LOW [16:16]
/// No description
GPIO20_LEVEL_LOW: u1 = 0,
/// GPIO20_LEVEL_HIGH [17:17]
/// No description
GPIO20_LEVEL_HIGH: u1 = 0,
/// GPIO20_EDGE_LOW [18:18]
/// No description
GPIO20_EDGE_LOW: u1 = 0,
/// GPIO20_EDGE_HIGH [19:19]
/// No description
GPIO20_EDGE_HIGH: u1 = 0,
/// GPIO21_LEVEL_LOW [20:20]
/// No description
GPIO21_LEVEL_LOW: u1 = 0,
/// GPIO21_LEVEL_HIGH [21:21]
/// No description
GPIO21_LEVEL_HIGH: u1 = 0,
/// GPIO21_EDGE_LOW [22:22]
/// No description
GPIO21_EDGE_LOW: u1 = 0,
/// GPIO21_EDGE_HIGH [23:23]
/// No description
GPIO21_EDGE_HIGH: u1 = 0,
/// GPIO22_LEVEL_LOW [24:24]
/// No description
GPIO22_LEVEL_LOW: u1 = 0,
/// GPIO22_LEVEL_HIGH [25:25]
/// No description
GPIO22_LEVEL_HIGH: u1 = 0,
/// GPIO22_EDGE_LOW [26:26]
/// No description
GPIO22_EDGE_LOW: u1 = 0,
/// GPIO22_EDGE_HIGH [27:27]
/// No description
GPIO22_EDGE_HIGH: u1 = 0,
/// GPIO23_LEVEL_LOW [28:28]
/// No description
GPIO23_LEVEL_LOW: u1 = 0,
/// GPIO23_LEVEL_HIGH [29:29]
/// No description
GPIO23_LEVEL_HIGH: u1 = 0,
/// GPIO23_EDGE_LOW [30:30]
/// No description
GPIO23_EDGE_LOW: u1 = 0,
/// GPIO23_EDGE_HIGH [31:31]
/// No description
GPIO23_EDGE_HIGH: u1 = 0,
};
/// Interrupt Enable for proc1
pub const PROC1_INTE2 = Register(PROC1_INTE2_val).init(base_address + 0x138);

/// PROC1_INTE1
const PROC1_INTE1_val = packed struct {
/// GPIO8_LEVEL_LOW [0:0]
/// No description
GPIO8_LEVEL_LOW: u1 = 0,
/// GPIO8_LEVEL_HIGH [1:1]
/// No description
GPIO8_LEVEL_HIGH: u1 = 0,
/// GPIO8_EDGE_LOW [2:2]
/// No description
GPIO8_EDGE_LOW: u1 = 0,
/// GPIO8_EDGE_HIGH [3:3]
/// No description
GPIO8_EDGE_HIGH: u1 = 0,
/// GPIO9_LEVEL_LOW [4:4]
/// No description
GPIO9_LEVEL_LOW: u1 = 0,
/// GPIO9_LEVEL_HIGH [5:5]
/// No description
GPIO9_LEVEL_HIGH: u1 = 0,
/// GPIO9_EDGE_LOW [6:6]
/// No description
GPIO9_EDGE_LOW: u1 = 0,
/// GPIO9_EDGE_HIGH [7:7]
/// No description
GPIO9_EDGE_HIGH: u1 = 0,
/// GPIO10_LEVEL_LOW [8:8]
/// No description
GPIO10_LEVEL_LOW: u1 = 0,
/// GPIO10_LEVEL_HIGH [9:9]
/// No description
GPIO10_LEVEL_HIGH: u1 = 0,
/// GPIO10_EDGE_LOW [10:10]
/// No description
GPIO10_EDGE_LOW: u1 = 0,
/// GPIO10_EDGE_HIGH [11:11]
/// No description
GPIO10_EDGE_HIGH: u1 = 0,
/// GPIO11_LEVEL_LOW [12:12]
/// No description
GPIO11_LEVEL_LOW: u1 = 0,
/// GPIO11_LEVEL_HIGH [13:13]
/// No description
GPIO11_LEVEL_HIGH: u1 = 0,
/// GPIO11_EDGE_LOW [14:14]
/// No description
GPIO11_EDGE_LOW: u1 = 0,
/// GPIO11_EDGE_HIGH [15:15]
/// No description
GPIO11_EDGE_HIGH: u1 = 0,
/// GPIO12_LEVEL_LOW [16:16]
/// No description
GPIO12_LEVEL_LOW: u1 = 0,
/// GPIO12_LEVEL_HIGH [17:17]
/// No description
GPIO12_LEVEL_HIGH: u1 = 0,
/// GPIO12_EDGE_LOW [18:18]
/// No description
GPIO12_EDGE_LOW: u1 = 0,
/// GPIO12_EDGE_HIGH [19:19]
/// No description
GPIO12_EDGE_HIGH: u1 = 0,
/// GPIO13_LEVEL_LOW [20:20]
/// No description
GPIO13_LEVEL_LOW: u1 = 0,
/// GPIO13_LEVEL_HIGH [21:21]
/// No description
GPIO13_LEVEL_HIGH: u1 = 0,
/// GPIO13_EDGE_LOW [22:22]
/// No description
GPIO13_EDGE_LOW: u1 = 0,
/// GPIO13_EDGE_HIGH [23:23]
/// No description
GPIO13_EDGE_HIGH: u1 = 0,
/// GPIO14_LEVEL_LOW [24:24]
/// No description
GPIO14_LEVEL_LOW: u1 = 0,
/// GPIO14_LEVEL_HIGH [25:25]
/// No description
GPIO14_LEVEL_HIGH: u1 = 0,
/// GPIO14_EDGE_LOW [26:26]
/// No description
GPIO14_EDGE_LOW: u1 = 0,
/// GPIO14_EDGE_HIGH [27:27]
/// No description
GPIO14_EDGE_HIGH: u1 = 0,
/// GPIO15_LEVEL_LOW [28:28]
/// No description
GPIO15_LEVEL_LOW: u1 = 0,
/// GPIO15_LEVEL_HIGH [29:29]
/// No description
GPIO15_LEVEL_HIGH: u1 = 0,
/// GPIO15_EDGE_LOW [30:30]
/// No description
GPIO15_EDGE_LOW: u1 = 0,
/// GPIO15_EDGE_HIGH [31:31]
/// No description
GPIO15_EDGE_HIGH: u1 = 0,
};
/// Interrupt Enable for proc1
pub const PROC1_INTE1 = Register(PROC1_INTE1_val).init(base_address + 0x134);

/// PROC1_INTE0
const PROC1_INTE0_val = packed struct {
/// GPIO0_LEVEL_LOW [0:0]
/// No description
GPIO0_LEVEL_LOW: u1 = 0,
/// GPIO0_LEVEL_HIGH [1:1]
/// No description
GPIO0_LEVEL_HIGH: u1 = 0,
/// GPIO0_EDGE_LOW [2:2]
/// No description
GPIO0_EDGE_LOW: u1 = 0,
/// GPIO0_EDGE_HIGH [3:3]
/// No description
GPIO0_EDGE_HIGH: u1 = 0,
/// GPIO1_LEVEL_LOW [4:4]
/// No description
GPIO1_LEVEL_LOW: u1 = 0,
/// GPIO1_LEVEL_HIGH [5:5]
/// No description
GPIO1_LEVEL_HIGH: u1 = 0,
/// GPIO1_EDGE_LOW [6:6]
/// No description
GPIO1_EDGE_LOW: u1 = 0,
/// GPIO1_EDGE_HIGH [7:7]
/// No description
GPIO1_EDGE_HIGH: u1 = 0,
/// GPIO2_LEVEL_LOW [8:8]
/// No description
GPIO2_LEVEL_LOW: u1 = 0,
/// GPIO2_LEVEL_HIGH [9:9]
/// No description
GPIO2_LEVEL_HIGH: u1 = 0,
/// GPIO2_EDGE_LOW [10:10]
/// No description
GPIO2_EDGE_LOW: u1 = 0,
/// GPIO2_EDGE_HIGH [11:11]
/// No description
GPIO2_EDGE_HIGH: u1 = 0,
/// GPIO3_LEVEL_LOW [12:12]
/// No description
GPIO3_LEVEL_LOW: u1 = 0,
/// GPIO3_LEVEL_HIGH [13:13]
/// No description
GPIO3_LEVEL_HIGH: u1 = 0,
/// GPIO3_EDGE_LOW [14:14]
/// No description
GPIO3_EDGE_LOW: u1 = 0,
/// GPIO3_EDGE_HIGH [15:15]
/// No description
GPIO3_EDGE_HIGH: u1 = 0,
/// GPIO4_LEVEL_LOW [16:16]
/// No description
GPIO4_LEVEL_LOW: u1 = 0,
/// GPIO4_LEVEL_HIGH [17:17]
/// No description
GPIO4_LEVEL_HIGH: u1 = 0,
/// GPIO4_EDGE_LOW [18:18]
/// No description
GPIO4_EDGE_LOW: u1 = 0,
/// GPIO4_EDGE_HIGH [19:19]
/// No description
GPIO4_EDGE_HIGH: u1 = 0,
/// GPIO5_LEVEL_LOW [20:20]
/// No description
GPIO5_LEVEL_LOW: u1 = 0,
/// GPIO5_LEVEL_HIGH [21:21]
/// No description
GPIO5_LEVEL_HIGH: u1 = 0,
/// GPIO5_EDGE_LOW [22:22]
/// No description
GPIO5_EDGE_LOW: u1 = 0,
/// GPIO5_EDGE_HIGH [23:23]
/// No description
GPIO5_EDGE_HIGH: u1 = 0,
/// GPIO6_LEVEL_LOW [24:24]
/// No description
GPIO6_LEVEL_LOW: u1 = 0,
/// GPIO6_LEVEL_HIGH [25:25]
/// No description
GPIO6_LEVEL_HIGH: u1 = 0,
/// GPIO6_EDGE_LOW [26:26]
/// No description
GPIO6_EDGE_LOW: u1 = 0,
/// GPIO6_EDGE_HIGH [27:27]
/// No description
GPIO6_EDGE_HIGH: u1 = 0,
/// GPIO7_LEVEL_LOW [28:28]
/// No description
GPIO7_LEVEL_LOW: u1 = 0,
/// GPIO7_LEVEL_HIGH [29:29]
/// No description
GPIO7_LEVEL_HIGH: u1 = 0,
/// GPIO7_EDGE_LOW [30:30]
/// No description
GPIO7_EDGE_LOW: u1 = 0,
/// GPIO7_EDGE_HIGH [31:31]
/// No description
GPIO7_EDGE_HIGH: u1 = 0,
};
/// Interrupt Enable for proc1
pub const PROC1_INTE0 = Register(PROC1_INTE0_val).init(base_address + 0x130);

/// PROC0_INTS3
const PROC0_INTS3_val = packed struct {
/// GPIO24_LEVEL_LOW [0:0]
/// No description
GPIO24_LEVEL_LOW: u1 = 0,
/// GPIO24_LEVEL_HIGH [1:1]
/// No description
GPIO24_LEVEL_HIGH: u1 = 0,
/// GPIO24_EDGE_LOW [2:2]
/// No description
GPIO24_EDGE_LOW: u1 = 0,
/// GPIO24_EDGE_HIGH [3:3]
/// No description
GPIO24_EDGE_HIGH: u1 = 0,
/// GPIO25_LEVEL_LOW [4:4]
/// No description
GPIO25_LEVEL_LOW: u1 = 0,
/// GPIO25_LEVEL_HIGH [5:5]
/// No description
GPIO25_LEVEL_HIGH: u1 = 0,
/// GPIO25_EDGE_LOW [6:6]
/// No description
GPIO25_EDGE_LOW: u1 = 0,
/// GPIO25_EDGE_HIGH [7:7]
/// No description
GPIO25_EDGE_HIGH: u1 = 0,
/// GPIO26_LEVEL_LOW [8:8]
/// No description
GPIO26_LEVEL_LOW: u1 = 0,
/// GPIO26_LEVEL_HIGH [9:9]
/// No description
GPIO26_LEVEL_HIGH: u1 = 0,
/// GPIO26_EDGE_LOW [10:10]
/// No description
GPIO26_EDGE_LOW: u1 = 0,
/// GPIO26_EDGE_HIGH [11:11]
/// No description
GPIO26_EDGE_HIGH: u1 = 0,
/// GPIO27_LEVEL_LOW [12:12]
/// No description
GPIO27_LEVEL_LOW: u1 = 0,
/// GPIO27_LEVEL_HIGH [13:13]
/// No description
GPIO27_LEVEL_HIGH: u1 = 0,
/// GPIO27_EDGE_LOW [14:14]
/// No description
GPIO27_EDGE_LOW: u1 = 0,
/// GPIO27_EDGE_HIGH [15:15]
/// No description
GPIO27_EDGE_HIGH: u1 = 0,
/// GPIO28_LEVEL_LOW [16:16]
/// No description
GPIO28_LEVEL_LOW: u1 = 0,
/// GPIO28_LEVEL_HIGH [17:17]
/// No description
GPIO28_LEVEL_HIGH: u1 = 0,
/// GPIO28_EDGE_LOW [18:18]
/// No description
GPIO28_EDGE_LOW: u1 = 0,
/// GPIO28_EDGE_HIGH [19:19]
/// No description
GPIO28_EDGE_HIGH: u1 = 0,
/// GPIO29_LEVEL_LOW [20:20]
/// No description
GPIO29_LEVEL_LOW: u1 = 0,
/// GPIO29_LEVEL_HIGH [21:21]
/// No description
GPIO29_LEVEL_HIGH: u1 = 0,
/// GPIO29_EDGE_LOW [22:22]
/// No description
GPIO29_EDGE_LOW: u1 = 0,
/// GPIO29_EDGE_HIGH [23:23]
/// No description
GPIO29_EDGE_HIGH: u1 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// Interrupt status after masking &amp; forcing for proc0
pub const PROC0_INTS3 = Register(PROC0_INTS3_val).init(base_address + 0x12c);

/// PROC0_INTS2
const PROC0_INTS2_val = packed struct {
/// GPIO16_LEVEL_LOW [0:0]
/// No description
GPIO16_LEVEL_LOW: u1 = 0,
/// GPIO16_LEVEL_HIGH [1:1]
/// No description
GPIO16_LEVEL_HIGH: u1 = 0,
/// GPIO16_EDGE_LOW [2:2]
/// No description
GPIO16_EDGE_LOW: u1 = 0,
/// GPIO16_EDGE_HIGH [3:3]
/// No description
GPIO16_EDGE_HIGH: u1 = 0,
/// GPIO17_LEVEL_LOW [4:4]
/// No description
GPIO17_LEVEL_LOW: u1 = 0,
/// GPIO17_LEVEL_HIGH [5:5]
/// No description
GPIO17_LEVEL_HIGH: u1 = 0,
/// GPIO17_EDGE_LOW [6:6]
/// No description
GPIO17_EDGE_LOW: u1 = 0,
/// GPIO17_EDGE_HIGH [7:7]
/// No description
GPIO17_EDGE_HIGH: u1 = 0,
/// GPIO18_LEVEL_LOW [8:8]
/// No description
GPIO18_LEVEL_LOW: u1 = 0,
/// GPIO18_LEVEL_HIGH [9:9]
/// No description
GPIO18_LEVEL_HIGH: u1 = 0,
/// GPIO18_EDGE_LOW [10:10]
/// No description
GPIO18_EDGE_LOW: u1 = 0,
/// GPIO18_EDGE_HIGH [11:11]
/// No description
GPIO18_EDGE_HIGH: u1 = 0,
/// GPIO19_LEVEL_LOW [12:12]
/// No description
GPIO19_LEVEL_LOW: u1 = 0,
/// GPIO19_LEVEL_HIGH [13:13]
/// No description
GPIO19_LEVEL_HIGH: u1 = 0,
/// GPIO19_EDGE_LOW [14:14]
/// No description
GPIO19_EDGE_LOW: u1 = 0,
/// GPIO19_EDGE_HIGH [15:15]
/// No description
GPIO19_EDGE_HIGH: u1 = 0,
/// GPIO20_LEVEL_LOW [16:16]
/// No description
GPIO20_LEVEL_LOW: u1 = 0,
/// GPIO20_LEVEL_HIGH [17:17]
/// No description
GPIO20_LEVEL_HIGH: u1 = 0,
/// GPIO20_EDGE_LOW [18:18]
/// No description
GPIO20_EDGE_LOW: u1 = 0,
/// GPIO20_EDGE_HIGH [19:19]
/// No description
GPIO20_EDGE_HIGH: u1 = 0,
/// GPIO21_LEVEL_LOW [20:20]
/// No description
GPIO21_LEVEL_LOW: u1 = 0,
/// GPIO21_LEVEL_HIGH [21:21]
/// No description
GPIO21_LEVEL_HIGH: u1 = 0,
/// GPIO21_EDGE_LOW [22:22]
/// No description
GPIO21_EDGE_LOW: u1 = 0,
/// GPIO21_EDGE_HIGH [23:23]
/// No description
GPIO21_EDGE_HIGH: u1 = 0,
/// GPIO22_LEVEL_LOW [24:24]
/// No description
GPIO22_LEVEL_LOW: u1 = 0,
/// GPIO22_LEVEL_HIGH [25:25]
/// No description
GPIO22_LEVEL_HIGH: u1 = 0,
/// GPIO22_EDGE_LOW [26:26]
/// No description
GPIO22_EDGE_LOW: u1 = 0,
/// GPIO22_EDGE_HIGH [27:27]
/// No description
GPIO22_EDGE_HIGH: u1 = 0,
/// GPIO23_LEVEL_LOW [28:28]
/// No description
GPIO23_LEVEL_LOW: u1 = 0,
/// GPIO23_LEVEL_HIGH [29:29]
/// No description
GPIO23_LEVEL_HIGH: u1 = 0,
/// GPIO23_EDGE_LOW [30:30]
/// No description
GPIO23_EDGE_LOW: u1 = 0,
/// GPIO23_EDGE_HIGH [31:31]
/// No description
GPIO23_EDGE_HIGH: u1 = 0,
};
/// Interrupt status after masking &amp; forcing for proc0
pub const PROC0_INTS2 = Register(PROC0_INTS2_val).init(base_address + 0x128);

/// PROC0_INTS1
const PROC0_INTS1_val = packed struct {
/// GPIO8_LEVEL_LOW [0:0]
/// No description
GPIO8_LEVEL_LOW: u1 = 0,
/// GPIO8_LEVEL_HIGH [1:1]
/// No description
GPIO8_LEVEL_HIGH: u1 = 0,
/// GPIO8_EDGE_LOW [2:2]
/// No description
GPIO8_EDGE_LOW: u1 = 0,
/// GPIO8_EDGE_HIGH [3:3]
/// No description
GPIO8_EDGE_HIGH: u1 = 0,
/// GPIO9_LEVEL_LOW [4:4]
/// No description
GPIO9_LEVEL_LOW: u1 = 0,
/// GPIO9_LEVEL_HIGH [5:5]
/// No description
GPIO9_LEVEL_HIGH: u1 = 0,
/// GPIO9_EDGE_LOW [6:6]
/// No description
GPIO9_EDGE_LOW: u1 = 0,
/// GPIO9_EDGE_HIGH [7:7]
/// No description
GPIO9_EDGE_HIGH: u1 = 0,
/// GPIO10_LEVEL_LOW [8:8]
/// No description
GPIO10_LEVEL_LOW: u1 = 0,
/// GPIO10_LEVEL_HIGH [9:9]
/// No description
GPIO10_LEVEL_HIGH: u1 = 0,
/// GPIO10_EDGE_LOW [10:10]
/// No description
GPIO10_EDGE_LOW: u1 = 0,
/// GPIO10_EDGE_HIGH [11:11]
/// No description
GPIO10_EDGE_HIGH: u1 = 0,
/// GPIO11_LEVEL_LOW [12:12]
/// No description
GPIO11_LEVEL_LOW: u1 = 0,
/// GPIO11_LEVEL_HIGH [13:13]
/// No description
GPIO11_LEVEL_HIGH: u1 = 0,
/// GPIO11_EDGE_LOW [14:14]
/// No description
GPIO11_EDGE_LOW: u1 = 0,
/// GPIO11_EDGE_HIGH [15:15]
/// No description
GPIO11_EDGE_HIGH: u1 = 0,
/// GPIO12_LEVEL_LOW [16:16]
/// No description
GPIO12_LEVEL_LOW: u1 = 0,
/// GPIO12_LEVEL_HIGH [17:17]
/// No description
GPIO12_LEVEL_HIGH: u1 = 0,
/// GPIO12_EDGE_LOW [18:18]
/// No description
GPIO12_EDGE_LOW: u1 = 0,
/// GPIO12_EDGE_HIGH [19:19]
/// No description
GPIO12_EDGE_HIGH: u1 = 0,
/// GPIO13_LEVEL_LOW [20:20]
/// No description
GPIO13_LEVEL_LOW: u1 = 0,
/// GPIO13_LEVEL_HIGH [21:21]
/// No description
GPIO13_LEVEL_HIGH: u1 = 0,
/// GPIO13_EDGE_LOW [22:22]
/// No description
GPIO13_EDGE_LOW: u1 = 0,
/// GPIO13_EDGE_HIGH [23:23]
/// No description
GPIO13_EDGE_HIGH: u1 = 0,
/// GPIO14_LEVEL_LOW [24:24]
/// No description
GPIO14_LEVEL_LOW: u1 = 0,
/// GPIO14_LEVEL_HIGH [25:25]
/// No description
GPIO14_LEVEL_HIGH: u1 = 0,
/// GPIO14_EDGE_LOW [26:26]
/// No description
GPIO14_EDGE_LOW: u1 = 0,
/// GPIO14_EDGE_HIGH [27:27]
/// No description
GPIO14_EDGE_HIGH: u1 = 0,
/// GPIO15_LEVEL_LOW [28:28]
/// No description
GPIO15_LEVEL_LOW: u1 = 0,
/// GPIO15_LEVEL_HIGH [29:29]
/// No description
GPIO15_LEVEL_HIGH: u1 = 0,
/// GPIO15_EDGE_LOW [30:30]
/// No description
GPIO15_EDGE_LOW: u1 = 0,
/// GPIO15_EDGE_HIGH [31:31]
/// No description
GPIO15_EDGE_HIGH: u1 = 0,
};
/// Interrupt status after masking &amp; forcing for proc0
pub const PROC0_INTS1 = Register(PROC0_INTS1_val).init(base_address + 0x124);

/// PROC0_INTS0
const PROC0_INTS0_val = packed struct {
/// GPIO0_LEVEL_LOW [0:0]
/// No description
GPIO0_LEVEL_LOW: u1 = 0,
/// GPIO0_LEVEL_HIGH [1:1]
/// No description
GPIO0_LEVEL_HIGH: u1 = 0,
/// GPIO0_EDGE_LOW [2:2]
/// No description
GPIO0_EDGE_LOW: u1 = 0,
/// GPIO0_EDGE_HIGH [3:3]
/// No description
GPIO0_EDGE_HIGH: u1 = 0,
/// GPIO1_LEVEL_LOW [4:4]
/// No description
GPIO1_LEVEL_LOW: u1 = 0,
/// GPIO1_LEVEL_HIGH [5:5]
/// No description
GPIO1_LEVEL_HIGH: u1 = 0,
/// GPIO1_EDGE_LOW [6:6]
/// No description
GPIO1_EDGE_LOW: u1 = 0,
/// GPIO1_EDGE_HIGH [7:7]
/// No description
GPIO1_EDGE_HIGH: u1 = 0,
/// GPIO2_LEVEL_LOW [8:8]
/// No description
GPIO2_LEVEL_LOW: u1 = 0,
/// GPIO2_LEVEL_HIGH [9:9]
/// No description
GPIO2_LEVEL_HIGH: u1 = 0,
/// GPIO2_EDGE_LOW [10:10]
/// No description
GPIO2_EDGE_LOW: u1 = 0,
/// GPIO2_EDGE_HIGH [11:11]
/// No description
GPIO2_EDGE_HIGH: u1 = 0,
/// GPIO3_LEVEL_LOW [12:12]
/// No description
GPIO3_LEVEL_LOW: u1 = 0,
/// GPIO3_LEVEL_HIGH [13:13]
/// No description
GPIO3_LEVEL_HIGH: u1 = 0,
/// GPIO3_EDGE_LOW [14:14]
/// No description
GPIO3_EDGE_LOW: u1 = 0,
/// GPIO3_EDGE_HIGH [15:15]
/// No description
GPIO3_EDGE_HIGH: u1 = 0,
/// GPIO4_LEVEL_LOW [16:16]
/// No description
GPIO4_LEVEL_LOW: u1 = 0,
/// GPIO4_LEVEL_HIGH [17:17]
/// No description
GPIO4_LEVEL_HIGH: u1 = 0,
/// GPIO4_EDGE_LOW [18:18]
/// No description
GPIO4_EDGE_LOW: u1 = 0,
/// GPIO4_EDGE_HIGH [19:19]
/// No description
GPIO4_EDGE_HIGH: u1 = 0,
/// GPIO5_LEVEL_LOW [20:20]
/// No description
GPIO5_LEVEL_LOW: u1 = 0,
/// GPIO5_LEVEL_HIGH [21:21]
/// No description
GPIO5_LEVEL_HIGH: u1 = 0,
/// GPIO5_EDGE_LOW [22:22]
/// No description
GPIO5_EDGE_LOW: u1 = 0,
/// GPIO5_EDGE_HIGH [23:23]
/// No description
GPIO5_EDGE_HIGH: u1 = 0,
/// GPIO6_LEVEL_LOW [24:24]
/// No description
GPIO6_LEVEL_LOW: u1 = 0,
/// GPIO6_LEVEL_HIGH [25:25]
/// No description
GPIO6_LEVEL_HIGH: u1 = 0,
/// GPIO6_EDGE_LOW [26:26]
/// No description
GPIO6_EDGE_LOW: u1 = 0,
/// GPIO6_EDGE_HIGH [27:27]
/// No description
GPIO6_EDGE_HIGH: u1 = 0,
/// GPIO7_LEVEL_LOW [28:28]
/// No description
GPIO7_LEVEL_LOW: u1 = 0,
/// GPIO7_LEVEL_HIGH [29:29]
/// No description
GPIO7_LEVEL_HIGH: u1 = 0,
/// GPIO7_EDGE_LOW [30:30]
/// No description
GPIO7_EDGE_LOW: u1 = 0,
/// GPIO7_EDGE_HIGH [31:31]
/// No description
GPIO7_EDGE_HIGH: u1 = 0,
};
/// Interrupt status after masking &amp; forcing for proc0
pub const PROC0_INTS0 = Register(PROC0_INTS0_val).init(base_address + 0x120);

/// PROC0_INTF3
const PROC0_INTF3_val = packed struct {
/// GPIO24_LEVEL_LOW [0:0]
/// No description
GPIO24_LEVEL_LOW: u1 = 0,
/// GPIO24_LEVEL_HIGH [1:1]
/// No description
GPIO24_LEVEL_HIGH: u1 = 0,
/// GPIO24_EDGE_LOW [2:2]
/// No description
GPIO24_EDGE_LOW: u1 = 0,
/// GPIO24_EDGE_HIGH [3:3]
/// No description
GPIO24_EDGE_HIGH: u1 = 0,
/// GPIO25_LEVEL_LOW [4:4]
/// No description
GPIO25_LEVEL_LOW: u1 = 0,
/// GPIO25_LEVEL_HIGH [5:5]
/// No description
GPIO25_LEVEL_HIGH: u1 = 0,
/// GPIO25_EDGE_LOW [6:6]
/// No description
GPIO25_EDGE_LOW: u1 = 0,
/// GPIO25_EDGE_HIGH [7:7]
/// No description
GPIO25_EDGE_HIGH: u1 = 0,
/// GPIO26_LEVEL_LOW [8:8]
/// No description
GPIO26_LEVEL_LOW: u1 = 0,
/// GPIO26_LEVEL_HIGH [9:9]
/// No description
GPIO26_LEVEL_HIGH: u1 = 0,
/// GPIO26_EDGE_LOW [10:10]
/// No description
GPIO26_EDGE_LOW: u1 = 0,
/// GPIO26_EDGE_HIGH [11:11]
/// No description
GPIO26_EDGE_HIGH: u1 = 0,
/// GPIO27_LEVEL_LOW [12:12]
/// No description
GPIO27_LEVEL_LOW: u1 = 0,
/// GPIO27_LEVEL_HIGH [13:13]
/// No description
GPIO27_LEVEL_HIGH: u1 = 0,
/// GPIO27_EDGE_LOW [14:14]
/// No description
GPIO27_EDGE_LOW: u1 = 0,
/// GPIO27_EDGE_HIGH [15:15]
/// No description
GPIO27_EDGE_HIGH: u1 = 0,
/// GPIO28_LEVEL_LOW [16:16]
/// No description
GPIO28_LEVEL_LOW: u1 = 0,
/// GPIO28_LEVEL_HIGH [17:17]
/// No description
GPIO28_LEVEL_HIGH: u1 = 0,
/// GPIO28_EDGE_LOW [18:18]
/// No description
GPIO28_EDGE_LOW: u1 = 0,
/// GPIO28_EDGE_HIGH [19:19]
/// No description
GPIO28_EDGE_HIGH: u1 = 0,
/// GPIO29_LEVEL_LOW [20:20]
/// No description
GPIO29_LEVEL_LOW: u1 = 0,
/// GPIO29_LEVEL_HIGH [21:21]
/// No description
GPIO29_LEVEL_HIGH: u1 = 0,
/// GPIO29_EDGE_LOW [22:22]
/// No description
GPIO29_EDGE_LOW: u1 = 0,
/// GPIO29_EDGE_HIGH [23:23]
/// No description
GPIO29_EDGE_HIGH: u1 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// Interrupt Force for proc0
pub const PROC0_INTF3 = Register(PROC0_INTF3_val).init(base_address + 0x11c);

/// PROC0_INTF2
const PROC0_INTF2_val = packed struct {
/// GPIO16_LEVEL_LOW [0:0]
/// No description
GPIO16_LEVEL_LOW: u1 = 0,
/// GPIO16_LEVEL_HIGH [1:1]
/// No description
GPIO16_LEVEL_HIGH: u1 = 0,
/// GPIO16_EDGE_LOW [2:2]
/// No description
GPIO16_EDGE_LOW: u1 = 0,
/// GPIO16_EDGE_HIGH [3:3]
/// No description
GPIO16_EDGE_HIGH: u1 = 0,
/// GPIO17_LEVEL_LOW [4:4]
/// No description
GPIO17_LEVEL_LOW: u1 = 0,
/// GPIO17_LEVEL_HIGH [5:5]
/// No description
GPIO17_LEVEL_HIGH: u1 = 0,
/// GPIO17_EDGE_LOW [6:6]
/// No description
GPIO17_EDGE_LOW: u1 = 0,
/// GPIO17_EDGE_HIGH [7:7]
/// No description
GPIO17_EDGE_HIGH: u1 = 0,
/// GPIO18_LEVEL_LOW [8:8]
/// No description
GPIO18_LEVEL_LOW: u1 = 0,
/// GPIO18_LEVEL_HIGH [9:9]
/// No description
GPIO18_LEVEL_HIGH: u1 = 0,
/// GPIO18_EDGE_LOW [10:10]
/// No description
GPIO18_EDGE_LOW: u1 = 0,
/// GPIO18_EDGE_HIGH [11:11]
/// No description
GPIO18_EDGE_HIGH: u1 = 0,
/// GPIO19_LEVEL_LOW [12:12]
/// No description
GPIO19_LEVEL_LOW: u1 = 0,
/// GPIO19_LEVEL_HIGH [13:13]
/// No description
GPIO19_LEVEL_HIGH: u1 = 0,
/// GPIO19_EDGE_LOW [14:14]
/// No description
GPIO19_EDGE_LOW: u1 = 0,
/// GPIO19_EDGE_HIGH [15:15]
/// No description
GPIO19_EDGE_HIGH: u1 = 0,
/// GPIO20_LEVEL_LOW [16:16]
/// No description
GPIO20_LEVEL_LOW: u1 = 0,
/// GPIO20_LEVEL_HIGH [17:17]
/// No description
GPIO20_LEVEL_HIGH: u1 = 0,
/// GPIO20_EDGE_LOW [18:18]
/// No description
GPIO20_EDGE_LOW: u1 = 0,
/// GPIO20_EDGE_HIGH [19:19]
/// No description
GPIO20_EDGE_HIGH: u1 = 0,
/// GPIO21_LEVEL_LOW [20:20]
/// No description
GPIO21_LEVEL_LOW: u1 = 0,
/// GPIO21_LEVEL_HIGH [21:21]
/// No description
GPIO21_LEVEL_HIGH: u1 = 0,
/// GPIO21_EDGE_LOW [22:22]
/// No description
GPIO21_EDGE_LOW: u1 = 0,
/// GPIO21_EDGE_HIGH [23:23]
/// No description
GPIO21_EDGE_HIGH: u1 = 0,
/// GPIO22_LEVEL_LOW [24:24]
/// No description
GPIO22_LEVEL_LOW: u1 = 0,
/// GPIO22_LEVEL_HIGH [25:25]
/// No description
GPIO22_LEVEL_HIGH: u1 = 0,
/// GPIO22_EDGE_LOW [26:26]
/// No description
GPIO22_EDGE_LOW: u1 = 0,
/// GPIO22_EDGE_HIGH [27:27]
/// No description
GPIO22_EDGE_HIGH: u1 = 0,
/// GPIO23_LEVEL_LOW [28:28]
/// No description
GPIO23_LEVEL_LOW: u1 = 0,
/// GPIO23_LEVEL_HIGH [29:29]
/// No description
GPIO23_LEVEL_HIGH: u1 = 0,
/// GPIO23_EDGE_LOW [30:30]
/// No description
GPIO23_EDGE_LOW: u1 = 0,
/// GPIO23_EDGE_HIGH [31:31]
/// No description
GPIO23_EDGE_HIGH: u1 = 0,
};
/// Interrupt Force for proc0
pub const PROC0_INTF2 = Register(PROC0_INTF2_val).init(base_address + 0x118);

/// PROC0_INTF1
const PROC0_INTF1_val = packed struct {
/// GPIO8_LEVEL_LOW [0:0]
/// No description
GPIO8_LEVEL_LOW: u1 = 0,
/// GPIO8_LEVEL_HIGH [1:1]
/// No description
GPIO8_LEVEL_HIGH: u1 = 0,
/// GPIO8_EDGE_LOW [2:2]
/// No description
GPIO8_EDGE_LOW: u1 = 0,
/// GPIO8_EDGE_HIGH [3:3]
/// No description
GPIO8_EDGE_HIGH: u1 = 0,
/// GPIO9_LEVEL_LOW [4:4]
/// No description
GPIO9_LEVEL_LOW: u1 = 0,
/// GPIO9_LEVEL_HIGH [5:5]
/// No description
GPIO9_LEVEL_HIGH: u1 = 0,
/// GPIO9_EDGE_LOW [6:6]
/// No description
GPIO9_EDGE_LOW: u1 = 0,
/// GPIO9_EDGE_HIGH [7:7]
/// No description
GPIO9_EDGE_HIGH: u1 = 0,
/// GPIO10_LEVEL_LOW [8:8]
/// No description
GPIO10_LEVEL_LOW: u1 = 0,
/// GPIO10_LEVEL_HIGH [9:9]
/// No description
GPIO10_LEVEL_HIGH: u1 = 0,
/// GPIO10_EDGE_LOW [10:10]
/// No description
GPIO10_EDGE_LOW: u1 = 0,
/// GPIO10_EDGE_HIGH [11:11]
/// No description
GPIO10_EDGE_HIGH: u1 = 0,
/// GPIO11_LEVEL_LOW [12:12]
/// No description
GPIO11_LEVEL_LOW: u1 = 0,
/// GPIO11_LEVEL_HIGH [13:13]
/// No description
GPIO11_LEVEL_HIGH: u1 = 0,
/// GPIO11_EDGE_LOW [14:14]
/// No description
GPIO11_EDGE_LOW: u1 = 0,
/// GPIO11_EDGE_HIGH [15:15]
/// No description
GPIO11_EDGE_HIGH: u1 = 0,
/// GPIO12_LEVEL_LOW [16:16]
/// No description
GPIO12_LEVEL_LOW: u1 = 0,
/// GPIO12_LEVEL_HIGH [17:17]
/// No description
GPIO12_LEVEL_HIGH: u1 = 0,
/// GPIO12_EDGE_LOW [18:18]
/// No description
GPIO12_EDGE_LOW: u1 = 0,
/// GPIO12_EDGE_HIGH [19:19]
/// No description
GPIO12_EDGE_HIGH: u1 = 0,
/// GPIO13_LEVEL_LOW [20:20]
/// No description
GPIO13_LEVEL_LOW: u1 = 0,
/// GPIO13_LEVEL_HIGH [21:21]
/// No description
GPIO13_LEVEL_HIGH: u1 = 0,
/// GPIO13_EDGE_LOW [22:22]
/// No description
GPIO13_EDGE_LOW: u1 = 0,
/// GPIO13_EDGE_HIGH [23:23]
/// No description
GPIO13_EDGE_HIGH: u1 = 0,
/// GPIO14_LEVEL_LOW [24:24]
/// No description
GPIO14_LEVEL_LOW: u1 = 0,
/// GPIO14_LEVEL_HIGH [25:25]
/// No description
GPIO14_LEVEL_HIGH: u1 = 0,
/// GPIO14_EDGE_LOW [26:26]
/// No description
GPIO14_EDGE_LOW: u1 = 0,
/// GPIO14_EDGE_HIGH [27:27]
/// No description
GPIO14_EDGE_HIGH: u1 = 0,
/// GPIO15_LEVEL_LOW [28:28]
/// No description
GPIO15_LEVEL_LOW: u1 = 0,
/// GPIO15_LEVEL_HIGH [29:29]
/// No description
GPIO15_LEVEL_HIGH: u1 = 0,
/// GPIO15_EDGE_LOW [30:30]
/// No description
GPIO15_EDGE_LOW: u1 = 0,
/// GPIO15_EDGE_HIGH [31:31]
/// No description
GPIO15_EDGE_HIGH: u1 = 0,
};
/// Interrupt Force for proc0
pub const PROC0_INTF1 = Register(PROC0_INTF1_val).init(base_address + 0x114);

/// PROC0_INTF0
const PROC0_INTF0_val = packed struct {
/// GPIO0_LEVEL_LOW [0:0]
/// No description
GPIO0_LEVEL_LOW: u1 = 0,
/// GPIO0_LEVEL_HIGH [1:1]
/// No description
GPIO0_LEVEL_HIGH: u1 = 0,
/// GPIO0_EDGE_LOW [2:2]
/// No description
GPIO0_EDGE_LOW: u1 = 0,
/// GPIO0_EDGE_HIGH [3:3]
/// No description
GPIO0_EDGE_HIGH: u1 = 0,
/// GPIO1_LEVEL_LOW [4:4]
/// No description
GPIO1_LEVEL_LOW: u1 = 0,
/// GPIO1_LEVEL_HIGH [5:5]
/// No description
GPIO1_LEVEL_HIGH: u1 = 0,
/// GPIO1_EDGE_LOW [6:6]
/// No description
GPIO1_EDGE_LOW: u1 = 0,
/// GPIO1_EDGE_HIGH [7:7]
/// No description
GPIO1_EDGE_HIGH: u1 = 0,
/// GPIO2_LEVEL_LOW [8:8]
/// No description
GPIO2_LEVEL_LOW: u1 = 0,
/// GPIO2_LEVEL_HIGH [9:9]
/// No description
GPIO2_LEVEL_HIGH: u1 = 0,
/// GPIO2_EDGE_LOW [10:10]
/// No description
GPIO2_EDGE_LOW: u1 = 0,
/// GPIO2_EDGE_HIGH [11:11]
/// No description
GPIO2_EDGE_HIGH: u1 = 0,
/// GPIO3_LEVEL_LOW [12:12]
/// No description
GPIO3_LEVEL_LOW: u1 = 0,
/// GPIO3_LEVEL_HIGH [13:13]
/// No description
GPIO3_LEVEL_HIGH: u1 = 0,
/// GPIO3_EDGE_LOW [14:14]
/// No description
GPIO3_EDGE_LOW: u1 = 0,
/// GPIO3_EDGE_HIGH [15:15]
/// No description
GPIO3_EDGE_HIGH: u1 = 0,
/// GPIO4_LEVEL_LOW [16:16]
/// No description
GPIO4_LEVEL_LOW: u1 = 0,
/// GPIO4_LEVEL_HIGH [17:17]
/// No description
GPIO4_LEVEL_HIGH: u1 = 0,
/// GPIO4_EDGE_LOW [18:18]
/// No description
GPIO4_EDGE_LOW: u1 = 0,
/// GPIO4_EDGE_HIGH [19:19]
/// No description
GPIO4_EDGE_HIGH: u1 = 0,
/// GPIO5_LEVEL_LOW [20:20]
/// No description
GPIO5_LEVEL_LOW: u1 = 0,
/// GPIO5_LEVEL_HIGH [21:21]
/// No description
GPIO5_LEVEL_HIGH: u1 = 0,
/// GPIO5_EDGE_LOW [22:22]
/// No description
GPIO5_EDGE_LOW: u1 = 0,
/// GPIO5_EDGE_HIGH [23:23]
/// No description
GPIO5_EDGE_HIGH: u1 = 0,
/// GPIO6_LEVEL_LOW [24:24]
/// No description
GPIO6_LEVEL_LOW: u1 = 0,
/// GPIO6_LEVEL_HIGH [25:25]
/// No description
GPIO6_LEVEL_HIGH: u1 = 0,
/// GPIO6_EDGE_LOW [26:26]
/// No description
GPIO6_EDGE_LOW: u1 = 0,
/// GPIO6_EDGE_HIGH [27:27]
/// No description
GPIO6_EDGE_HIGH: u1 = 0,
/// GPIO7_LEVEL_LOW [28:28]
/// No description
GPIO7_LEVEL_LOW: u1 = 0,
/// GPIO7_LEVEL_HIGH [29:29]
/// No description
GPIO7_LEVEL_HIGH: u1 = 0,
/// GPIO7_EDGE_LOW [30:30]
/// No description
GPIO7_EDGE_LOW: u1 = 0,
/// GPIO7_EDGE_HIGH [31:31]
/// No description
GPIO7_EDGE_HIGH: u1 = 0,
};
/// Interrupt Force for proc0
pub const PROC0_INTF0 = Register(PROC0_INTF0_val).init(base_address + 0x110);

/// PROC0_INTE3
const PROC0_INTE3_val = packed struct {
/// GPIO24_LEVEL_LOW [0:0]
/// No description
GPIO24_LEVEL_LOW: u1 = 0,
/// GPIO24_LEVEL_HIGH [1:1]
/// No description
GPIO24_LEVEL_HIGH: u1 = 0,
/// GPIO24_EDGE_LOW [2:2]
/// No description
GPIO24_EDGE_LOW: u1 = 0,
/// GPIO24_EDGE_HIGH [3:3]
/// No description
GPIO24_EDGE_HIGH: u1 = 0,
/// GPIO25_LEVEL_LOW [4:4]
/// No description
GPIO25_LEVEL_LOW: u1 = 0,
/// GPIO25_LEVEL_HIGH [5:5]
/// No description
GPIO25_LEVEL_HIGH: u1 = 0,
/// GPIO25_EDGE_LOW [6:6]
/// No description
GPIO25_EDGE_LOW: u1 = 0,
/// GPIO25_EDGE_HIGH [7:7]
/// No description
GPIO25_EDGE_HIGH: u1 = 0,
/// GPIO26_LEVEL_LOW [8:8]
/// No description
GPIO26_LEVEL_LOW: u1 = 0,
/// GPIO26_LEVEL_HIGH [9:9]
/// No description
GPIO26_LEVEL_HIGH: u1 = 0,
/// GPIO26_EDGE_LOW [10:10]
/// No description
GPIO26_EDGE_LOW: u1 = 0,
/// GPIO26_EDGE_HIGH [11:11]
/// No description
GPIO26_EDGE_HIGH: u1 = 0,
/// GPIO27_LEVEL_LOW [12:12]
/// No description
GPIO27_LEVEL_LOW: u1 = 0,
/// GPIO27_LEVEL_HIGH [13:13]
/// No description
GPIO27_LEVEL_HIGH: u1 = 0,
/// GPIO27_EDGE_LOW [14:14]
/// No description
GPIO27_EDGE_LOW: u1 = 0,
/// GPIO27_EDGE_HIGH [15:15]
/// No description
GPIO27_EDGE_HIGH: u1 = 0,
/// GPIO28_LEVEL_LOW [16:16]
/// No description
GPIO28_LEVEL_LOW: u1 = 0,
/// GPIO28_LEVEL_HIGH [17:17]
/// No description
GPIO28_LEVEL_HIGH: u1 = 0,
/// GPIO28_EDGE_LOW [18:18]
/// No description
GPIO28_EDGE_LOW: u1 = 0,
/// GPIO28_EDGE_HIGH [19:19]
/// No description
GPIO28_EDGE_HIGH: u1 = 0,
/// GPIO29_LEVEL_LOW [20:20]
/// No description
GPIO29_LEVEL_LOW: u1 = 0,
/// GPIO29_LEVEL_HIGH [21:21]
/// No description
GPIO29_LEVEL_HIGH: u1 = 0,
/// GPIO29_EDGE_LOW [22:22]
/// No description
GPIO29_EDGE_LOW: u1 = 0,
/// GPIO29_EDGE_HIGH [23:23]
/// No description
GPIO29_EDGE_HIGH: u1 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// Interrupt Enable for proc0
pub const PROC0_INTE3 = Register(PROC0_INTE3_val).init(base_address + 0x10c);

/// PROC0_INTE2
const PROC0_INTE2_val = packed struct {
/// GPIO16_LEVEL_LOW [0:0]
/// No description
GPIO16_LEVEL_LOW: u1 = 0,
/// GPIO16_LEVEL_HIGH [1:1]
/// No description
GPIO16_LEVEL_HIGH: u1 = 0,
/// GPIO16_EDGE_LOW [2:2]
/// No description
GPIO16_EDGE_LOW: u1 = 0,
/// GPIO16_EDGE_HIGH [3:3]
/// No description
GPIO16_EDGE_HIGH: u1 = 0,
/// GPIO17_LEVEL_LOW [4:4]
/// No description
GPIO17_LEVEL_LOW: u1 = 0,
/// GPIO17_LEVEL_HIGH [5:5]
/// No description
GPIO17_LEVEL_HIGH: u1 = 0,
/// GPIO17_EDGE_LOW [6:6]
/// No description
GPIO17_EDGE_LOW: u1 = 0,
/// GPIO17_EDGE_HIGH [7:7]
/// No description
GPIO17_EDGE_HIGH: u1 = 0,
/// GPIO18_LEVEL_LOW [8:8]
/// No description
GPIO18_LEVEL_LOW: u1 = 0,
/// GPIO18_LEVEL_HIGH [9:9]
/// No description
GPIO18_LEVEL_HIGH: u1 = 0,
/// GPIO18_EDGE_LOW [10:10]
/// No description
GPIO18_EDGE_LOW: u1 = 0,
/// GPIO18_EDGE_HIGH [11:11]
/// No description
GPIO18_EDGE_HIGH: u1 = 0,
/// GPIO19_LEVEL_LOW [12:12]
/// No description
GPIO19_LEVEL_LOW: u1 = 0,
/// GPIO19_LEVEL_HIGH [13:13]
/// No description
GPIO19_LEVEL_HIGH: u1 = 0,
/// GPIO19_EDGE_LOW [14:14]
/// No description
GPIO19_EDGE_LOW: u1 = 0,
/// GPIO19_EDGE_HIGH [15:15]
/// No description
GPIO19_EDGE_HIGH: u1 = 0,
/// GPIO20_LEVEL_LOW [16:16]
/// No description
GPIO20_LEVEL_LOW: u1 = 0,
/// GPIO20_LEVEL_HIGH [17:17]
/// No description
GPIO20_LEVEL_HIGH: u1 = 0,
/// GPIO20_EDGE_LOW [18:18]
/// No description
GPIO20_EDGE_LOW: u1 = 0,
/// GPIO20_EDGE_HIGH [19:19]
/// No description
GPIO20_EDGE_HIGH: u1 = 0,
/// GPIO21_LEVEL_LOW [20:20]
/// No description
GPIO21_LEVEL_LOW: u1 = 0,
/// GPIO21_LEVEL_HIGH [21:21]
/// No description
GPIO21_LEVEL_HIGH: u1 = 0,
/// GPIO21_EDGE_LOW [22:22]
/// No description
GPIO21_EDGE_LOW: u1 = 0,
/// GPIO21_EDGE_HIGH [23:23]
/// No description
GPIO21_EDGE_HIGH: u1 = 0,
/// GPIO22_LEVEL_LOW [24:24]
/// No description
GPIO22_LEVEL_LOW: u1 = 0,
/// GPIO22_LEVEL_HIGH [25:25]
/// No description
GPIO22_LEVEL_HIGH: u1 = 0,
/// GPIO22_EDGE_LOW [26:26]
/// No description
GPIO22_EDGE_LOW: u1 = 0,
/// GPIO22_EDGE_HIGH [27:27]
/// No description
GPIO22_EDGE_HIGH: u1 = 0,
/// GPIO23_LEVEL_LOW [28:28]
/// No description
GPIO23_LEVEL_LOW: u1 = 0,
/// GPIO23_LEVEL_HIGH [29:29]
/// No description
GPIO23_LEVEL_HIGH: u1 = 0,
/// GPIO23_EDGE_LOW [30:30]
/// No description
GPIO23_EDGE_LOW: u1 = 0,
/// GPIO23_EDGE_HIGH [31:31]
/// No description
GPIO23_EDGE_HIGH: u1 = 0,
};
/// Interrupt Enable for proc0
pub const PROC0_INTE2 = Register(PROC0_INTE2_val).init(base_address + 0x108);

/// PROC0_INTE1
const PROC0_INTE1_val = packed struct {
/// GPIO8_LEVEL_LOW [0:0]
/// No description
GPIO8_LEVEL_LOW: u1 = 0,
/// GPIO8_LEVEL_HIGH [1:1]
/// No description
GPIO8_LEVEL_HIGH: u1 = 0,
/// GPIO8_EDGE_LOW [2:2]
/// No description
GPIO8_EDGE_LOW: u1 = 0,
/// GPIO8_EDGE_HIGH [3:3]
/// No description
GPIO8_EDGE_HIGH: u1 = 0,
/// GPIO9_LEVEL_LOW [4:4]
/// No description
GPIO9_LEVEL_LOW: u1 = 0,
/// GPIO9_LEVEL_HIGH [5:5]
/// No description
GPIO9_LEVEL_HIGH: u1 = 0,
/// GPIO9_EDGE_LOW [6:6]
/// No description
GPIO9_EDGE_LOW: u1 = 0,
/// GPIO9_EDGE_HIGH [7:7]
/// No description
GPIO9_EDGE_HIGH: u1 = 0,
/// GPIO10_LEVEL_LOW [8:8]
/// No description
GPIO10_LEVEL_LOW: u1 = 0,
/// GPIO10_LEVEL_HIGH [9:9]
/// No description
GPIO10_LEVEL_HIGH: u1 = 0,
/// GPIO10_EDGE_LOW [10:10]
/// No description
GPIO10_EDGE_LOW: u1 = 0,
/// GPIO10_EDGE_HIGH [11:11]
/// No description
GPIO10_EDGE_HIGH: u1 = 0,
/// GPIO11_LEVEL_LOW [12:12]
/// No description
GPIO11_LEVEL_LOW: u1 = 0,
/// GPIO11_LEVEL_HIGH [13:13]
/// No description
GPIO11_LEVEL_HIGH: u1 = 0,
/// GPIO11_EDGE_LOW [14:14]
/// No description
GPIO11_EDGE_LOW: u1 = 0,
/// GPIO11_EDGE_HIGH [15:15]
/// No description
GPIO11_EDGE_HIGH: u1 = 0,
/// GPIO12_LEVEL_LOW [16:16]
/// No description
GPIO12_LEVEL_LOW: u1 = 0,
/// GPIO12_LEVEL_HIGH [17:17]
/// No description
GPIO12_LEVEL_HIGH: u1 = 0,
/// GPIO12_EDGE_LOW [18:18]
/// No description
GPIO12_EDGE_LOW: u1 = 0,
/// GPIO12_EDGE_HIGH [19:19]
/// No description
GPIO12_EDGE_HIGH: u1 = 0,
/// GPIO13_LEVEL_LOW [20:20]
/// No description
GPIO13_LEVEL_LOW: u1 = 0,
/// GPIO13_LEVEL_HIGH [21:21]
/// No description
GPIO13_LEVEL_HIGH: u1 = 0,
/// GPIO13_EDGE_LOW [22:22]
/// No description
GPIO13_EDGE_LOW: u1 = 0,
/// GPIO13_EDGE_HIGH [23:23]
/// No description
GPIO13_EDGE_HIGH: u1 = 0,
/// GPIO14_LEVEL_LOW [24:24]
/// No description
GPIO14_LEVEL_LOW: u1 = 0,
/// GPIO14_LEVEL_HIGH [25:25]
/// No description
GPIO14_LEVEL_HIGH: u1 = 0,
/// GPIO14_EDGE_LOW [26:26]
/// No description
GPIO14_EDGE_LOW: u1 = 0,
/// GPIO14_EDGE_HIGH [27:27]
/// No description
GPIO14_EDGE_HIGH: u1 = 0,
/// GPIO15_LEVEL_LOW [28:28]
/// No description
GPIO15_LEVEL_LOW: u1 = 0,
/// GPIO15_LEVEL_HIGH [29:29]
/// No description
GPIO15_LEVEL_HIGH: u1 = 0,
/// GPIO15_EDGE_LOW [30:30]
/// No description
GPIO15_EDGE_LOW: u1 = 0,
/// GPIO15_EDGE_HIGH [31:31]
/// No description
GPIO15_EDGE_HIGH: u1 = 0,
};
/// Interrupt Enable for proc0
pub const PROC0_INTE1 = Register(PROC0_INTE1_val).init(base_address + 0x104);

/// PROC0_INTE0
const PROC0_INTE0_val = packed struct {
/// GPIO0_LEVEL_LOW [0:0]
/// No description
GPIO0_LEVEL_LOW: u1 = 0,
/// GPIO0_LEVEL_HIGH [1:1]
/// No description
GPIO0_LEVEL_HIGH: u1 = 0,
/// GPIO0_EDGE_LOW [2:2]
/// No description
GPIO0_EDGE_LOW: u1 = 0,
/// GPIO0_EDGE_HIGH [3:3]
/// No description
GPIO0_EDGE_HIGH: u1 = 0,
/// GPIO1_LEVEL_LOW [4:4]
/// No description
GPIO1_LEVEL_LOW: u1 = 0,
/// GPIO1_LEVEL_HIGH [5:5]
/// No description
GPIO1_LEVEL_HIGH: u1 = 0,
/// GPIO1_EDGE_LOW [6:6]
/// No description
GPIO1_EDGE_LOW: u1 = 0,
/// GPIO1_EDGE_HIGH [7:7]
/// No description
GPIO1_EDGE_HIGH: u1 = 0,
/// GPIO2_LEVEL_LOW [8:8]
/// No description
GPIO2_LEVEL_LOW: u1 = 0,
/// GPIO2_LEVEL_HIGH [9:9]
/// No description
GPIO2_LEVEL_HIGH: u1 = 0,
/// GPIO2_EDGE_LOW [10:10]
/// No description
GPIO2_EDGE_LOW: u1 = 0,
/// GPIO2_EDGE_HIGH [11:11]
/// No description
GPIO2_EDGE_HIGH: u1 = 0,
/// GPIO3_LEVEL_LOW [12:12]
/// No description
GPIO3_LEVEL_LOW: u1 = 0,
/// GPIO3_LEVEL_HIGH [13:13]
/// No description
GPIO3_LEVEL_HIGH: u1 = 0,
/// GPIO3_EDGE_LOW [14:14]
/// No description
GPIO3_EDGE_LOW: u1 = 0,
/// GPIO3_EDGE_HIGH [15:15]
/// No description
GPIO3_EDGE_HIGH: u1 = 0,
/// GPIO4_LEVEL_LOW [16:16]
/// No description
GPIO4_LEVEL_LOW: u1 = 0,
/// GPIO4_LEVEL_HIGH [17:17]
/// No description
GPIO4_LEVEL_HIGH: u1 = 0,
/// GPIO4_EDGE_LOW [18:18]
/// No description
GPIO4_EDGE_LOW: u1 = 0,
/// GPIO4_EDGE_HIGH [19:19]
/// No description
GPIO4_EDGE_HIGH: u1 = 0,
/// GPIO5_LEVEL_LOW [20:20]
/// No description
GPIO5_LEVEL_LOW: u1 = 0,
/// GPIO5_LEVEL_HIGH [21:21]
/// No description
GPIO5_LEVEL_HIGH: u1 = 0,
/// GPIO5_EDGE_LOW [22:22]
/// No description
GPIO5_EDGE_LOW: u1 = 0,
/// GPIO5_EDGE_HIGH [23:23]
/// No description
GPIO5_EDGE_HIGH: u1 = 0,
/// GPIO6_LEVEL_LOW [24:24]
/// No description
GPIO6_LEVEL_LOW: u1 = 0,
/// GPIO6_LEVEL_HIGH [25:25]
/// No description
GPIO6_LEVEL_HIGH: u1 = 0,
/// GPIO6_EDGE_LOW [26:26]
/// No description
GPIO6_EDGE_LOW: u1 = 0,
/// GPIO6_EDGE_HIGH [27:27]
/// No description
GPIO6_EDGE_HIGH: u1 = 0,
/// GPIO7_LEVEL_LOW [28:28]
/// No description
GPIO7_LEVEL_LOW: u1 = 0,
/// GPIO7_LEVEL_HIGH [29:29]
/// No description
GPIO7_LEVEL_HIGH: u1 = 0,
/// GPIO7_EDGE_LOW [30:30]
/// No description
GPIO7_EDGE_LOW: u1 = 0,
/// GPIO7_EDGE_HIGH [31:31]
/// No description
GPIO7_EDGE_HIGH: u1 = 0,
};
/// Interrupt Enable for proc0
pub const PROC0_INTE0 = Register(PROC0_INTE0_val).init(base_address + 0x100);

/// INTR3
const INTR3_val = packed struct {
/// GPIO24_LEVEL_LOW [0:0]
/// No description
GPIO24_LEVEL_LOW: u1 = 0,
/// GPIO24_LEVEL_HIGH [1:1]
/// No description
GPIO24_LEVEL_HIGH: u1 = 0,
/// GPIO24_EDGE_LOW [2:2]
/// No description
GPIO24_EDGE_LOW: u1 = 0,
/// GPIO24_EDGE_HIGH [3:3]
/// No description
GPIO24_EDGE_HIGH: u1 = 0,
/// GPIO25_LEVEL_LOW [4:4]
/// No description
GPIO25_LEVEL_LOW: u1 = 0,
/// GPIO25_LEVEL_HIGH [5:5]
/// No description
GPIO25_LEVEL_HIGH: u1 = 0,
/// GPIO25_EDGE_LOW [6:6]
/// No description
GPIO25_EDGE_LOW: u1 = 0,
/// GPIO25_EDGE_HIGH [7:7]
/// No description
GPIO25_EDGE_HIGH: u1 = 0,
/// GPIO26_LEVEL_LOW [8:8]
/// No description
GPIO26_LEVEL_LOW: u1 = 0,
/// GPIO26_LEVEL_HIGH [9:9]
/// No description
GPIO26_LEVEL_HIGH: u1 = 0,
/// GPIO26_EDGE_LOW [10:10]
/// No description
GPIO26_EDGE_LOW: u1 = 0,
/// GPIO26_EDGE_HIGH [11:11]
/// No description
GPIO26_EDGE_HIGH: u1 = 0,
/// GPIO27_LEVEL_LOW [12:12]
/// No description
GPIO27_LEVEL_LOW: u1 = 0,
/// GPIO27_LEVEL_HIGH [13:13]
/// No description
GPIO27_LEVEL_HIGH: u1 = 0,
/// GPIO27_EDGE_LOW [14:14]
/// No description
GPIO27_EDGE_LOW: u1 = 0,
/// GPIO27_EDGE_HIGH [15:15]
/// No description
GPIO27_EDGE_HIGH: u1 = 0,
/// GPIO28_LEVEL_LOW [16:16]
/// No description
GPIO28_LEVEL_LOW: u1 = 0,
/// GPIO28_LEVEL_HIGH [17:17]
/// No description
GPIO28_LEVEL_HIGH: u1 = 0,
/// GPIO28_EDGE_LOW [18:18]
/// No description
GPIO28_EDGE_LOW: u1 = 0,
/// GPIO28_EDGE_HIGH [19:19]
/// No description
GPIO28_EDGE_HIGH: u1 = 0,
/// GPIO29_LEVEL_LOW [20:20]
/// No description
GPIO29_LEVEL_LOW: u1 = 0,
/// GPIO29_LEVEL_HIGH [21:21]
/// No description
GPIO29_LEVEL_HIGH: u1 = 0,
/// GPIO29_EDGE_LOW [22:22]
/// No description
GPIO29_EDGE_LOW: u1 = 0,
/// GPIO29_EDGE_HIGH [23:23]
/// No description
GPIO29_EDGE_HIGH: u1 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// Raw Interrupts
pub const INTR3 = Register(INTR3_val).init(base_address + 0xfc);

/// INTR2
const INTR2_val = packed struct {
/// GPIO16_LEVEL_LOW [0:0]
/// No description
GPIO16_LEVEL_LOW: u1 = 0,
/// GPIO16_LEVEL_HIGH [1:1]
/// No description
GPIO16_LEVEL_HIGH: u1 = 0,
/// GPIO16_EDGE_LOW [2:2]
/// No description
GPIO16_EDGE_LOW: u1 = 0,
/// GPIO16_EDGE_HIGH [3:3]
/// No description
GPIO16_EDGE_HIGH: u1 = 0,
/// GPIO17_LEVEL_LOW [4:4]
/// No description
GPIO17_LEVEL_LOW: u1 = 0,
/// GPIO17_LEVEL_HIGH [5:5]
/// No description
GPIO17_LEVEL_HIGH: u1 = 0,
/// GPIO17_EDGE_LOW [6:6]
/// No description
GPIO17_EDGE_LOW: u1 = 0,
/// GPIO17_EDGE_HIGH [7:7]
/// No description
GPIO17_EDGE_HIGH: u1 = 0,
/// GPIO18_LEVEL_LOW [8:8]
/// No description
GPIO18_LEVEL_LOW: u1 = 0,
/// GPIO18_LEVEL_HIGH [9:9]
/// No description
GPIO18_LEVEL_HIGH: u1 = 0,
/// GPIO18_EDGE_LOW [10:10]
/// No description
GPIO18_EDGE_LOW: u1 = 0,
/// GPIO18_EDGE_HIGH [11:11]
/// No description
GPIO18_EDGE_HIGH: u1 = 0,
/// GPIO19_LEVEL_LOW [12:12]
/// No description
GPIO19_LEVEL_LOW: u1 = 0,
/// GPIO19_LEVEL_HIGH [13:13]
/// No description
GPIO19_LEVEL_HIGH: u1 = 0,
/// GPIO19_EDGE_LOW [14:14]
/// No description
GPIO19_EDGE_LOW: u1 = 0,
/// GPIO19_EDGE_HIGH [15:15]
/// No description
GPIO19_EDGE_HIGH: u1 = 0,
/// GPIO20_LEVEL_LOW [16:16]
/// No description
GPIO20_LEVEL_LOW: u1 = 0,
/// GPIO20_LEVEL_HIGH [17:17]
/// No description
GPIO20_LEVEL_HIGH: u1 = 0,
/// GPIO20_EDGE_LOW [18:18]
/// No description
GPIO20_EDGE_LOW: u1 = 0,
/// GPIO20_EDGE_HIGH [19:19]
/// No description
GPIO20_EDGE_HIGH: u1 = 0,
/// GPIO21_LEVEL_LOW [20:20]
/// No description
GPIO21_LEVEL_LOW: u1 = 0,
/// GPIO21_LEVEL_HIGH [21:21]
/// No description
GPIO21_LEVEL_HIGH: u1 = 0,
/// GPIO21_EDGE_LOW [22:22]
/// No description
GPIO21_EDGE_LOW: u1 = 0,
/// GPIO21_EDGE_HIGH [23:23]
/// No description
GPIO21_EDGE_HIGH: u1 = 0,
/// GPIO22_LEVEL_LOW [24:24]
/// No description
GPIO22_LEVEL_LOW: u1 = 0,
/// GPIO22_LEVEL_HIGH [25:25]
/// No description
GPIO22_LEVEL_HIGH: u1 = 0,
/// GPIO22_EDGE_LOW [26:26]
/// No description
GPIO22_EDGE_LOW: u1 = 0,
/// GPIO22_EDGE_HIGH [27:27]
/// No description
GPIO22_EDGE_HIGH: u1 = 0,
/// GPIO23_LEVEL_LOW [28:28]
/// No description
GPIO23_LEVEL_LOW: u1 = 0,
/// GPIO23_LEVEL_HIGH [29:29]
/// No description
GPIO23_LEVEL_HIGH: u1 = 0,
/// GPIO23_EDGE_LOW [30:30]
/// No description
GPIO23_EDGE_LOW: u1 = 0,
/// GPIO23_EDGE_HIGH [31:31]
/// No description
GPIO23_EDGE_HIGH: u1 = 0,
};
/// Raw Interrupts
pub const INTR2 = Register(INTR2_val).init(base_address + 0xf8);

/// INTR1
const INTR1_val = packed struct {
/// GPIO8_LEVEL_LOW [0:0]
/// No description
GPIO8_LEVEL_LOW: u1 = 0,
/// GPIO8_LEVEL_HIGH [1:1]
/// No description
GPIO8_LEVEL_HIGH: u1 = 0,
/// GPIO8_EDGE_LOW [2:2]
/// No description
GPIO8_EDGE_LOW: u1 = 0,
/// GPIO8_EDGE_HIGH [3:3]
/// No description
GPIO8_EDGE_HIGH: u1 = 0,
/// GPIO9_LEVEL_LOW [4:4]
/// No description
GPIO9_LEVEL_LOW: u1 = 0,
/// GPIO9_LEVEL_HIGH [5:5]
/// No description
GPIO9_LEVEL_HIGH: u1 = 0,
/// GPIO9_EDGE_LOW [6:6]
/// No description
GPIO9_EDGE_LOW: u1 = 0,
/// GPIO9_EDGE_HIGH [7:7]
/// No description
GPIO9_EDGE_HIGH: u1 = 0,
/// GPIO10_LEVEL_LOW [8:8]
/// No description
GPIO10_LEVEL_LOW: u1 = 0,
/// GPIO10_LEVEL_HIGH [9:9]
/// No description
GPIO10_LEVEL_HIGH: u1 = 0,
/// GPIO10_EDGE_LOW [10:10]
/// No description
GPIO10_EDGE_LOW: u1 = 0,
/// GPIO10_EDGE_HIGH [11:11]
/// No description
GPIO10_EDGE_HIGH: u1 = 0,
/// GPIO11_LEVEL_LOW [12:12]
/// No description
GPIO11_LEVEL_LOW: u1 = 0,
/// GPIO11_LEVEL_HIGH [13:13]
/// No description
GPIO11_LEVEL_HIGH: u1 = 0,
/// GPIO11_EDGE_LOW [14:14]
/// No description
GPIO11_EDGE_LOW: u1 = 0,
/// GPIO11_EDGE_HIGH [15:15]
/// No description
GPIO11_EDGE_HIGH: u1 = 0,
/// GPIO12_LEVEL_LOW [16:16]
/// No description
GPIO12_LEVEL_LOW: u1 = 0,
/// GPIO12_LEVEL_HIGH [17:17]
/// No description
GPIO12_LEVEL_HIGH: u1 = 0,
/// GPIO12_EDGE_LOW [18:18]
/// No description
GPIO12_EDGE_LOW: u1 = 0,
/// GPIO12_EDGE_HIGH [19:19]
/// No description
GPIO12_EDGE_HIGH: u1 = 0,
/// GPIO13_LEVEL_LOW [20:20]
/// No description
GPIO13_LEVEL_LOW: u1 = 0,
/// GPIO13_LEVEL_HIGH [21:21]
/// No description
GPIO13_LEVEL_HIGH: u1 = 0,
/// GPIO13_EDGE_LOW [22:22]
/// No description
GPIO13_EDGE_LOW: u1 = 0,
/// GPIO13_EDGE_HIGH [23:23]
/// No description
GPIO13_EDGE_HIGH: u1 = 0,
/// GPIO14_LEVEL_LOW [24:24]
/// No description
GPIO14_LEVEL_LOW: u1 = 0,
/// GPIO14_LEVEL_HIGH [25:25]
/// No description
GPIO14_LEVEL_HIGH: u1 = 0,
/// GPIO14_EDGE_LOW [26:26]
/// No description
GPIO14_EDGE_LOW: u1 = 0,
/// GPIO14_EDGE_HIGH [27:27]
/// No description
GPIO14_EDGE_HIGH: u1 = 0,
/// GPIO15_LEVEL_LOW [28:28]
/// No description
GPIO15_LEVEL_LOW: u1 = 0,
/// GPIO15_LEVEL_HIGH [29:29]
/// No description
GPIO15_LEVEL_HIGH: u1 = 0,
/// GPIO15_EDGE_LOW [30:30]
/// No description
GPIO15_EDGE_LOW: u1 = 0,
/// GPIO15_EDGE_HIGH [31:31]
/// No description
GPIO15_EDGE_HIGH: u1 = 0,
};
/// Raw Interrupts
pub const INTR1 = Register(INTR1_val).init(base_address + 0xf4);

/// INTR0
const INTR0_val = packed struct {
/// GPIO0_LEVEL_LOW [0:0]
/// No description
GPIO0_LEVEL_LOW: u1 = 0,
/// GPIO0_LEVEL_HIGH [1:1]
/// No description
GPIO0_LEVEL_HIGH: u1 = 0,
/// GPIO0_EDGE_LOW [2:2]
/// No description
GPIO0_EDGE_LOW: u1 = 0,
/// GPIO0_EDGE_HIGH [3:3]
/// No description
GPIO0_EDGE_HIGH: u1 = 0,
/// GPIO1_LEVEL_LOW [4:4]
/// No description
GPIO1_LEVEL_LOW: u1 = 0,
/// GPIO1_LEVEL_HIGH [5:5]
/// No description
GPIO1_LEVEL_HIGH: u1 = 0,
/// GPIO1_EDGE_LOW [6:6]
/// No description
GPIO1_EDGE_LOW: u1 = 0,
/// GPIO1_EDGE_HIGH [7:7]
/// No description
GPIO1_EDGE_HIGH: u1 = 0,
/// GPIO2_LEVEL_LOW [8:8]
/// No description
GPIO2_LEVEL_LOW: u1 = 0,
/// GPIO2_LEVEL_HIGH [9:9]
/// No description
GPIO2_LEVEL_HIGH: u1 = 0,
/// GPIO2_EDGE_LOW [10:10]
/// No description
GPIO2_EDGE_LOW: u1 = 0,
/// GPIO2_EDGE_HIGH [11:11]
/// No description
GPIO2_EDGE_HIGH: u1 = 0,
/// GPIO3_LEVEL_LOW [12:12]
/// No description
GPIO3_LEVEL_LOW: u1 = 0,
/// GPIO3_LEVEL_HIGH [13:13]
/// No description
GPIO3_LEVEL_HIGH: u1 = 0,
/// GPIO3_EDGE_LOW [14:14]
/// No description
GPIO3_EDGE_LOW: u1 = 0,
/// GPIO3_EDGE_HIGH [15:15]
/// No description
GPIO3_EDGE_HIGH: u1 = 0,
/// GPIO4_LEVEL_LOW [16:16]
/// No description
GPIO4_LEVEL_LOW: u1 = 0,
/// GPIO4_LEVEL_HIGH [17:17]
/// No description
GPIO4_LEVEL_HIGH: u1 = 0,
/// GPIO4_EDGE_LOW [18:18]
/// No description
GPIO4_EDGE_LOW: u1 = 0,
/// GPIO4_EDGE_HIGH [19:19]
/// No description
GPIO4_EDGE_HIGH: u1 = 0,
/// GPIO5_LEVEL_LOW [20:20]
/// No description
GPIO5_LEVEL_LOW: u1 = 0,
/// GPIO5_LEVEL_HIGH [21:21]
/// No description
GPIO5_LEVEL_HIGH: u1 = 0,
/// GPIO5_EDGE_LOW [22:22]
/// No description
GPIO5_EDGE_LOW: u1 = 0,
/// GPIO5_EDGE_HIGH [23:23]
/// No description
GPIO5_EDGE_HIGH: u1 = 0,
/// GPIO6_LEVEL_LOW [24:24]
/// No description
GPIO6_LEVEL_LOW: u1 = 0,
/// GPIO6_LEVEL_HIGH [25:25]
/// No description
GPIO6_LEVEL_HIGH: u1 = 0,
/// GPIO6_EDGE_LOW [26:26]
/// No description
GPIO6_EDGE_LOW: u1 = 0,
/// GPIO6_EDGE_HIGH [27:27]
/// No description
GPIO6_EDGE_HIGH: u1 = 0,
/// GPIO7_LEVEL_LOW [28:28]
/// No description
GPIO7_LEVEL_LOW: u1 = 0,
/// GPIO7_LEVEL_HIGH [29:29]
/// No description
GPIO7_LEVEL_HIGH: u1 = 0,
/// GPIO7_EDGE_LOW [30:30]
/// No description
GPIO7_EDGE_LOW: u1 = 0,
/// GPIO7_EDGE_HIGH [31:31]
/// No description
GPIO7_EDGE_HIGH: u1 = 0,
};
/// Raw Interrupts
pub const INTR0 = Register(INTR0_val).init(base_address + 0xf0);

/// GPIO29_CTRL
const GPIO29_CTRL_val = packed struct {
/// FUNCSEL [0:4]
/// 0-31 -&gt; selects pin function according to the gpio table\n
FUNCSEL: u5 = 31,
/// unused [5:7]
_unused5: u3 = 0,
/// OUTOVER [8:9]
/// No description
OUTOVER: u2 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEOVER [12:13]
/// No description
OEOVER: u2 = 0,
/// unused [14:15]
_unused14: u2 = 0,
/// INOVER [16:17]
/// No description
INOVER: u2 = 0,
/// unused [18:27]
_unused18: u6 = 0,
_unused24: u4 = 0,
/// IRQOVER [28:29]
/// No description
IRQOVER: u2 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// GPIO control including function select and overrides.
pub const GPIO29_CTRL = Register(GPIO29_CTRL_val).init(base_address + 0xec);

/// GPIO29_STATUS
const GPIO29_STATUS_val = packed struct {
/// unused [0:7]
_unused0: u8 = 0,
/// OUTFROMPERI [8:8]
/// output signal from selected peripheral, before register override is applied
OUTFROMPERI: u1 = 0,
/// OUTTOPAD [9:9]
/// output signal to pad after register override is applied
OUTTOPAD: u1 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEFROMPERI [12:12]
/// output enable from selected peripheral, before register override is applied
OEFROMPERI: u1 = 0,
/// OETOPAD [13:13]
/// output enable to pad after register override is applied
OETOPAD: u1 = 0,
/// unused [14:16]
_unused14: u2 = 0,
_unused16: u1 = 0,
/// INFROMPAD [17:17]
/// input signal from pad, before override is applied
INFROMPAD: u1 = 0,
/// unused [18:18]
_unused18: u1 = 0,
/// INTOPERI [19:19]
/// input signal to peripheral, after override is applied
INTOPERI: u1 = 0,
/// unused [20:23]
_unused20: u4 = 0,
/// IRQFROMPAD [24:24]
/// interrupt from pad before override is applied
IRQFROMPAD: u1 = 0,
/// unused [25:25]
_unused25: u1 = 0,
/// IRQTOPROC [26:26]
/// interrupt to processors, after override is applied
IRQTOPROC: u1 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// GPIO status
pub const GPIO29_STATUS = Register(GPIO29_STATUS_val).init(base_address + 0xe8);

/// GPIO28_CTRL
const GPIO28_CTRL_val = packed struct {
/// FUNCSEL [0:4]
/// 0-31 -&gt; selects pin function according to the gpio table\n
FUNCSEL: u5 = 31,
/// unused [5:7]
_unused5: u3 = 0,
/// OUTOVER [8:9]
/// No description
OUTOVER: u2 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEOVER [12:13]
/// No description
OEOVER: u2 = 0,
/// unused [14:15]
_unused14: u2 = 0,
/// INOVER [16:17]
/// No description
INOVER: u2 = 0,
/// unused [18:27]
_unused18: u6 = 0,
_unused24: u4 = 0,
/// IRQOVER [28:29]
/// No description
IRQOVER: u2 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// GPIO control including function select and overrides.
pub const GPIO28_CTRL = Register(GPIO28_CTRL_val).init(base_address + 0xe4);

/// GPIO28_STATUS
const GPIO28_STATUS_val = packed struct {
/// unused [0:7]
_unused0: u8 = 0,
/// OUTFROMPERI [8:8]
/// output signal from selected peripheral, before register override is applied
OUTFROMPERI: u1 = 0,
/// OUTTOPAD [9:9]
/// output signal to pad after register override is applied
OUTTOPAD: u1 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEFROMPERI [12:12]
/// output enable from selected peripheral, before register override is applied
OEFROMPERI: u1 = 0,
/// OETOPAD [13:13]
/// output enable to pad after register override is applied
OETOPAD: u1 = 0,
/// unused [14:16]
_unused14: u2 = 0,
_unused16: u1 = 0,
/// INFROMPAD [17:17]
/// input signal from pad, before override is applied
INFROMPAD: u1 = 0,
/// unused [18:18]
_unused18: u1 = 0,
/// INTOPERI [19:19]
/// input signal to peripheral, after override is applied
INTOPERI: u1 = 0,
/// unused [20:23]
_unused20: u4 = 0,
/// IRQFROMPAD [24:24]
/// interrupt from pad before override is applied
IRQFROMPAD: u1 = 0,
/// unused [25:25]
_unused25: u1 = 0,
/// IRQTOPROC [26:26]
/// interrupt to processors, after override is applied
IRQTOPROC: u1 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// GPIO status
pub const GPIO28_STATUS = Register(GPIO28_STATUS_val).init(base_address + 0xe0);

/// GPIO27_CTRL
const GPIO27_CTRL_val = packed struct {
/// FUNCSEL [0:4]
/// 0-31 -&gt; selects pin function according to the gpio table\n
FUNCSEL: u5 = 31,
/// unused [5:7]
_unused5: u3 = 0,
/// OUTOVER [8:9]
/// No description
OUTOVER: u2 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEOVER [12:13]
/// No description
OEOVER: u2 = 0,
/// unused [14:15]
_unused14: u2 = 0,
/// INOVER [16:17]
/// No description
INOVER: u2 = 0,
/// unused [18:27]
_unused18: u6 = 0,
_unused24: u4 = 0,
/// IRQOVER [28:29]
/// No description
IRQOVER: u2 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// GPIO control including function select and overrides.
pub const GPIO27_CTRL = Register(GPIO27_CTRL_val).init(base_address + 0xdc);

/// GPIO27_STATUS
const GPIO27_STATUS_val = packed struct {
/// unused [0:7]
_unused0: u8 = 0,
/// OUTFROMPERI [8:8]
/// output signal from selected peripheral, before register override is applied
OUTFROMPERI: u1 = 0,
/// OUTTOPAD [9:9]
/// output signal to pad after register override is applied
OUTTOPAD: u1 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEFROMPERI [12:12]
/// output enable from selected peripheral, before register override is applied
OEFROMPERI: u1 = 0,
/// OETOPAD [13:13]
/// output enable to pad after register override is applied
OETOPAD: u1 = 0,
/// unused [14:16]
_unused14: u2 = 0,
_unused16: u1 = 0,
/// INFROMPAD [17:17]
/// input signal from pad, before override is applied
INFROMPAD: u1 = 0,
/// unused [18:18]
_unused18: u1 = 0,
/// INTOPERI [19:19]
/// input signal to peripheral, after override is applied
INTOPERI: u1 = 0,
/// unused [20:23]
_unused20: u4 = 0,
/// IRQFROMPAD [24:24]
/// interrupt from pad before override is applied
IRQFROMPAD: u1 = 0,
/// unused [25:25]
_unused25: u1 = 0,
/// IRQTOPROC [26:26]
/// interrupt to processors, after override is applied
IRQTOPROC: u1 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// GPIO status
pub const GPIO27_STATUS = Register(GPIO27_STATUS_val).init(base_address + 0xd8);

/// GPIO26_CTRL
const GPIO26_CTRL_val = packed struct {
/// FUNCSEL [0:4]
/// 0-31 -&gt; selects pin function according to the gpio table\n
FUNCSEL: u5 = 31,
/// unused [5:7]
_unused5: u3 = 0,
/// OUTOVER [8:9]
/// No description
OUTOVER: u2 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEOVER [12:13]
/// No description
OEOVER: u2 = 0,
/// unused [14:15]
_unused14: u2 = 0,
/// INOVER [16:17]
/// No description
INOVER: u2 = 0,
/// unused [18:27]
_unused18: u6 = 0,
_unused24: u4 = 0,
/// IRQOVER [28:29]
/// No description
IRQOVER: u2 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// GPIO control including function select and overrides.
pub const GPIO26_CTRL = Register(GPIO26_CTRL_val).init(base_address + 0xd4);

/// GPIO26_STATUS
const GPIO26_STATUS_val = packed struct {
/// unused [0:7]
_unused0: u8 = 0,
/// OUTFROMPERI [8:8]
/// output signal from selected peripheral, before register override is applied
OUTFROMPERI: u1 = 0,
/// OUTTOPAD [9:9]
/// output signal to pad after register override is applied
OUTTOPAD: u1 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEFROMPERI [12:12]
/// output enable from selected peripheral, before register override is applied
OEFROMPERI: u1 = 0,
/// OETOPAD [13:13]
/// output enable to pad after register override is applied
OETOPAD: u1 = 0,
/// unused [14:16]
_unused14: u2 = 0,
_unused16: u1 = 0,
/// INFROMPAD [17:17]
/// input signal from pad, before override is applied
INFROMPAD: u1 = 0,
/// unused [18:18]
_unused18: u1 = 0,
/// INTOPERI [19:19]
/// input signal to peripheral, after override is applied
INTOPERI: u1 = 0,
/// unused [20:23]
_unused20: u4 = 0,
/// IRQFROMPAD [24:24]
/// interrupt from pad before override is applied
IRQFROMPAD: u1 = 0,
/// unused [25:25]
_unused25: u1 = 0,
/// IRQTOPROC [26:26]
/// interrupt to processors, after override is applied
IRQTOPROC: u1 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// GPIO status
pub const GPIO26_STATUS = Register(GPIO26_STATUS_val).init(base_address + 0xd0);

/// GPIO25_CTRL
const GPIO25_CTRL_val = packed struct {
/// FUNCSEL [0:4]
/// 0-31 -&gt; selects pin function according to the gpio table\n
FUNCSEL: u5 = 31,
/// unused [5:7]
_unused5: u3 = 0,
/// OUTOVER [8:9]
/// No description
OUTOVER: u2 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEOVER [12:13]
/// No description
OEOVER: u2 = 0,
/// unused [14:15]
_unused14: u2 = 0,
/// INOVER [16:17]
/// No description
INOVER: u2 = 0,
/// unused [18:27]
_unused18: u6 = 0,
_unused24: u4 = 0,
/// IRQOVER [28:29]
/// No description
IRQOVER: u2 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// GPIO control including function select and overrides.
pub const GPIO25_CTRL = Register(GPIO25_CTRL_val).init(base_address + 0xcc);

/// GPIO25_STATUS
const GPIO25_STATUS_val = packed struct {
/// unused [0:7]
_unused0: u8 = 0,
/// OUTFROMPERI [8:8]
/// output signal from selected peripheral, before register override is applied
OUTFROMPERI: u1 = 0,
/// OUTTOPAD [9:9]
/// output signal to pad after register override is applied
OUTTOPAD: u1 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEFROMPERI [12:12]
/// output enable from selected peripheral, before register override is applied
OEFROMPERI: u1 = 0,
/// OETOPAD [13:13]
/// output enable to pad after register override is applied
OETOPAD: u1 = 0,
/// unused [14:16]
_unused14: u2 = 0,
_unused16: u1 = 0,
/// INFROMPAD [17:17]
/// input signal from pad, before override is applied
INFROMPAD: u1 = 0,
/// unused [18:18]
_unused18: u1 = 0,
/// INTOPERI [19:19]
/// input signal to peripheral, after override is applied
INTOPERI: u1 = 0,
/// unused [20:23]
_unused20: u4 = 0,
/// IRQFROMPAD [24:24]
/// interrupt from pad before override is applied
IRQFROMPAD: u1 = 0,
/// unused [25:25]
_unused25: u1 = 0,
/// IRQTOPROC [26:26]
/// interrupt to processors, after override is applied
IRQTOPROC: u1 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// GPIO status
pub const GPIO25_STATUS = Register(GPIO25_STATUS_val).init(base_address + 0xc8);

/// GPIO24_CTRL
const GPIO24_CTRL_val = packed struct {
/// FUNCSEL [0:4]
/// 0-31 -&gt; selects pin function according to the gpio table\n
FUNCSEL: u5 = 31,
/// unused [5:7]
_unused5: u3 = 0,
/// OUTOVER [8:9]
/// No description
OUTOVER: u2 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEOVER [12:13]
/// No description
OEOVER: u2 = 0,
/// unused [14:15]
_unused14: u2 = 0,
/// INOVER [16:17]
/// No description
INOVER: u2 = 0,
/// unused [18:27]
_unused18: u6 = 0,
_unused24: u4 = 0,
/// IRQOVER [28:29]
/// No description
IRQOVER: u2 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// GPIO control including function select and overrides.
pub const GPIO24_CTRL = Register(GPIO24_CTRL_val).init(base_address + 0xc4);

/// GPIO24_STATUS
const GPIO24_STATUS_val = packed struct {
/// unused [0:7]
_unused0: u8 = 0,
/// OUTFROMPERI [8:8]
/// output signal from selected peripheral, before register override is applied
OUTFROMPERI: u1 = 0,
/// OUTTOPAD [9:9]
/// output signal to pad after register override is applied
OUTTOPAD: u1 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEFROMPERI [12:12]
/// output enable from selected peripheral, before register override is applied
OEFROMPERI: u1 = 0,
/// OETOPAD [13:13]
/// output enable to pad after register override is applied
OETOPAD: u1 = 0,
/// unused [14:16]
_unused14: u2 = 0,
_unused16: u1 = 0,
/// INFROMPAD [17:17]
/// input signal from pad, before override is applied
INFROMPAD: u1 = 0,
/// unused [18:18]
_unused18: u1 = 0,
/// INTOPERI [19:19]
/// input signal to peripheral, after override is applied
INTOPERI: u1 = 0,
/// unused [20:23]
_unused20: u4 = 0,
/// IRQFROMPAD [24:24]
/// interrupt from pad before override is applied
IRQFROMPAD: u1 = 0,
/// unused [25:25]
_unused25: u1 = 0,
/// IRQTOPROC [26:26]
/// interrupt to processors, after override is applied
IRQTOPROC: u1 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// GPIO status
pub const GPIO24_STATUS = Register(GPIO24_STATUS_val).init(base_address + 0xc0);

/// GPIO23_CTRL
const GPIO23_CTRL_val = packed struct {
/// FUNCSEL [0:4]
/// 0-31 -&gt; selects pin function according to the gpio table\n
FUNCSEL: u5 = 31,
/// unused [5:7]
_unused5: u3 = 0,
/// OUTOVER [8:9]
/// No description
OUTOVER: u2 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEOVER [12:13]
/// No description
OEOVER: u2 = 0,
/// unused [14:15]
_unused14: u2 = 0,
/// INOVER [16:17]
/// No description
INOVER: u2 = 0,
/// unused [18:27]
_unused18: u6 = 0,
_unused24: u4 = 0,
/// IRQOVER [28:29]
/// No description
IRQOVER: u2 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// GPIO control including function select and overrides.
pub const GPIO23_CTRL = Register(GPIO23_CTRL_val).init(base_address + 0xbc);

/// GPIO23_STATUS
const GPIO23_STATUS_val = packed struct {
/// unused [0:7]
_unused0: u8 = 0,
/// OUTFROMPERI [8:8]
/// output signal from selected peripheral, before register override is applied
OUTFROMPERI: u1 = 0,
/// OUTTOPAD [9:9]
/// output signal to pad after register override is applied
OUTTOPAD: u1 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEFROMPERI [12:12]
/// output enable from selected peripheral, before register override is applied
OEFROMPERI: u1 = 0,
/// OETOPAD [13:13]
/// output enable to pad after register override is applied
OETOPAD: u1 = 0,
/// unused [14:16]
_unused14: u2 = 0,
_unused16: u1 = 0,
/// INFROMPAD [17:17]
/// input signal from pad, before override is applied
INFROMPAD: u1 = 0,
/// unused [18:18]
_unused18: u1 = 0,
/// INTOPERI [19:19]
/// input signal to peripheral, after override is applied
INTOPERI: u1 = 0,
/// unused [20:23]
_unused20: u4 = 0,
/// IRQFROMPAD [24:24]
/// interrupt from pad before override is applied
IRQFROMPAD: u1 = 0,
/// unused [25:25]
_unused25: u1 = 0,
/// IRQTOPROC [26:26]
/// interrupt to processors, after override is applied
IRQTOPROC: u1 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// GPIO status
pub const GPIO23_STATUS = Register(GPIO23_STATUS_val).init(base_address + 0xb8);

/// GPIO22_CTRL
const GPIO22_CTRL_val = packed struct {
/// FUNCSEL [0:4]
/// 0-31 -&gt; selects pin function according to the gpio table\n
FUNCSEL: u5 = 31,
/// unused [5:7]
_unused5: u3 = 0,
/// OUTOVER [8:9]
/// No description
OUTOVER: u2 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEOVER [12:13]
/// No description
OEOVER: u2 = 0,
/// unused [14:15]
_unused14: u2 = 0,
/// INOVER [16:17]
/// No description
INOVER: u2 = 0,
/// unused [18:27]
_unused18: u6 = 0,
_unused24: u4 = 0,
/// IRQOVER [28:29]
/// No description
IRQOVER: u2 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// GPIO control including function select and overrides.
pub const GPIO22_CTRL = Register(GPIO22_CTRL_val).init(base_address + 0xb4);

/// GPIO22_STATUS
const GPIO22_STATUS_val = packed struct {
/// unused [0:7]
_unused0: u8 = 0,
/// OUTFROMPERI [8:8]
/// output signal from selected peripheral, before register override is applied
OUTFROMPERI: u1 = 0,
/// OUTTOPAD [9:9]
/// output signal to pad after register override is applied
OUTTOPAD: u1 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEFROMPERI [12:12]
/// output enable from selected peripheral, before register override is applied
OEFROMPERI: u1 = 0,
/// OETOPAD [13:13]
/// output enable to pad after register override is applied
OETOPAD: u1 = 0,
/// unused [14:16]
_unused14: u2 = 0,
_unused16: u1 = 0,
/// INFROMPAD [17:17]
/// input signal from pad, before override is applied
INFROMPAD: u1 = 0,
/// unused [18:18]
_unused18: u1 = 0,
/// INTOPERI [19:19]
/// input signal to peripheral, after override is applied
INTOPERI: u1 = 0,
/// unused [20:23]
_unused20: u4 = 0,
/// IRQFROMPAD [24:24]
/// interrupt from pad before override is applied
IRQFROMPAD: u1 = 0,
/// unused [25:25]
_unused25: u1 = 0,
/// IRQTOPROC [26:26]
/// interrupt to processors, after override is applied
IRQTOPROC: u1 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// GPIO status
pub const GPIO22_STATUS = Register(GPIO22_STATUS_val).init(base_address + 0xb0);

/// GPIO21_CTRL
const GPIO21_CTRL_val = packed struct {
/// FUNCSEL [0:4]
/// 0-31 -&gt; selects pin function according to the gpio table\n
FUNCSEL: u5 = 31,
/// unused [5:7]
_unused5: u3 = 0,
/// OUTOVER [8:9]
/// No description
OUTOVER: u2 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEOVER [12:13]
/// No description
OEOVER: u2 = 0,
/// unused [14:15]
_unused14: u2 = 0,
/// INOVER [16:17]
/// No description
INOVER: u2 = 0,
/// unused [18:27]
_unused18: u6 = 0,
_unused24: u4 = 0,
/// IRQOVER [28:29]
/// No description
IRQOVER: u2 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// GPIO control including function select and overrides.
pub const GPIO21_CTRL = Register(GPIO21_CTRL_val).init(base_address + 0xac);

/// GPIO21_STATUS
const GPIO21_STATUS_val = packed struct {
/// unused [0:7]
_unused0: u8 = 0,
/// OUTFROMPERI [8:8]
/// output signal from selected peripheral, before register override is applied
OUTFROMPERI: u1 = 0,
/// OUTTOPAD [9:9]
/// output signal to pad after register override is applied
OUTTOPAD: u1 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEFROMPERI [12:12]
/// output enable from selected peripheral, before register override is applied
OEFROMPERI: u1 = 0,
/// OETOPAD [13:13]
/// output enable to pad after register override is applied
OETOPAD: u1 = 0,
/// unused [14:16]
_unused14: u2 = 0,
_unused16: u1 = 0,
/// INFROMPAD [17:17]
/// input signal from pad, before override is applied
INFROMPAD: u1 = 0,
/// unused [18:18]
_unused18: u1 = 0,
/// INTOPERI [19:19]
/// input signal to peripheral, after override is applied
INTOPERI: u1 = 0,
/// unused [20:23]
_unused20: u4 = 0,
/// IRQFROMPAD [24:24]
/// interrupt from pad before override is applied
IRQFROMPAD: u1 = 0,
/// unused [25:25]
_unused25: u1 = 0,
/// IRQTOPROC [26:26]
/// interrupt to processors, after override is applied
IRQTOPROC: u1 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// GPIO status
pub const GPIO21_STATUS = Register(GPIO21_STATUS_val).init(base_address + 0xa8);

/// GPIO20_CTRL
const GPIO20_CTRL_val = packed struct {
/// FUNCSEL [0:4]
/// 0-31 -&gt; selects pin function according to the gpio table\n
FUNCSEL: u5 = 31,
/// unused [5:7]
_unused5: u3 = 0,
/// OUTOVER [8:9]
/// No description
OUTOVER: u2 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEOVER [12:13]
/// No description
OEOVER: u2 = 0,
/// unused [14:15]
_unused14: u2 = 0,
/// INOVER [16:17]
/// No description
INOVER: u2 = 0,
/// unused [18:27]
_unused18: u6 = 0,
_unused24: u4 = 0,
/// IRQOVER [28:29]
/// No description
IRQOVER: u2 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// GPIO control including function select and overrides.
pub const GPIO20_CTRL = Register(GPIO20_CTRL_val).init(base_address + 0xa4);

/// GPIO20_STATUS
const GPIO20_STATUS_val = packed struct {
/// unused [0:7]
_unused0: u8 = 0,
/// OUTFROMPERI [8:8]
/// output signal from selected peripheral, before register override is applied
OUTFROMPERI: u1 = 0,
/// OUTTOPAD [9:9]
/// output signal to pad after register override is applied
OUTTOPAD: u1 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEFROMPERI [12:12]
/// output enable from selected peripheral, before register override is applied
OEFROMPERI: u1 = 0,
/// OETOPAD [13:13]
/// output enable to pad after register override is applied
OETOPAD: u1 = 0,
/// unused [14:16]
_unused14: u2 = 0,
_unused16: u1 = 0,
/// INFROMPAD [17:17]
/// input signal from pad, before override is applied
INFROMPAD: u1 = 0,
/// unused [18:18]
_unused18: u1 = 0,
/// INTOPERI [19:19]
/// input signal to peripheral, after override is applied
INTOPERI: u1 = 0,
/// unused [20:23]
_unused20: u4 = 0,
/// IRQFROMPAD [24:24]
/// interrupt from pad before override is applied
IRQFROMPAD: u1 = 0,
/// unused [25:25]
_unused25: u1 = 0,
/// IRQTOPROC [26:26]
/// interrupt to processors, after override is applied
IRQTOPROC: u1 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// GPIO status
pub const GPIO20_STATUS = Register(GPIO20_STATUS_val).init(base_address + 0xa0);

/// GPIO19_CTRL
const GPIO19_CTRL_val = packed struct {
/// FUNCSEL [0:4]
/// 0-31 -&gt; selects pin function according to the gpio table\n
FUNCSEL: u5 = 31,
/// unused [5:7]
_unused5: u3 = 0,
/// OUTOVER [8:9]
/// No description
OUTOVER: u2 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEOVER [12:13]
/// No description
OEOVER: u2 = 0,
/// unused [14:15]
_unused14: u2 = 0,
/// INOVER [16:17]
/// No description
INOVER: u2 = 0,
/// unused [18:27]
_unused18: u6 = 0,
_unused24: u4 = 0,
/// IRQOVER [28:29]
/// No description
IRQOVER: u2 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// GPIO control including function select and overrides.
pub const GPIO19_CTRL = Register(GPIO19_CTRL_val).init(base_address + 0x9c);

/// GPIO19_STATUS
const GPIO19_STATUS_val = packed struct {
/// unused [0:7]
_unused0: u8 = 0,
/// OUTFROMPERI [8:8]
/// output signal from selected peripheral, before register override is applied
OUTFROMPERI: u1 = 0,
/// OUTTOPAD [9:9]
/// output signal to pad after register override is applied
OUTTOPAD: u1 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEFROMPERI [12:12]
/// output enable from selected peripheral, before register override is applied
OEFROMPERI: u1 = 0,
/// OETOPAD [13:13]
/// output enable to pad after register override is applied
OETOPAD: u1 = 0,
/// unused [14:16]
_unused14: u2 = 0,
_unused16: u1 = 0,
/// INFROMPAD [17:17]
/// input signal from pad, before override is applied
INFROMPAD: u1 = 0,
/// unused [18:18]
_unused18: u1 = 0,
/// INTOPERI [19:19]
/// input signal to peripheral, after override is applied
INTOPERI: u1 = 0,
/// unused [20:23]
_unused20: u4 = 0,
/// IRQFROMPAD [24:24]
/// interrupt from pad before override is applied
IRQFROMPAD: u1 = 0,
/// unused [25:25]
_unused25: u1 = 0,
/// IRQTOPROC [26:26]
/// interrupt to processors, after override is applied
IRQTOPROC: u1 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// GPIO status
pub const GPIO19_STATUS = Register(GPIO19_STATUS_val).init(base_address + 0x98);

/// GPIO18_CTRL
const GPIO18_CTRL_val = packed struct {
/// FUNCSEL [0:4]
/// 0-31 -&gt; selects pin function according to the gpio table\n
FUNCSEL: u5 = 31,
/// unused [5:7]
_unused5: u3 = 0,
/// OUTOVER [8:9]
/// No description
OUTOVER: u2 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEOVER [12:13]
/// No description
OEOVER: u2 = 0,
/// unused [14:15]
_unused14: u2 = 0,
/// INOVER [16:17]
/// No description
INOVER: u2 = 0,
/// unused [18:27]
_unused18: u6 = 0,
_unused24: u4 = 0,
/// IRQOVER [28:29]
/// No description
IRQOVER: u2 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// GPIO control including function select and overrides.
pub const GPIO18_CTRL = Register(GPIO18_CTRL_val).init(base_address + 0x94);

/// GPIO18_STATUS
const GPIO18_STATUS_val = packed struct {
/// unused [0:7]
_unused0: u8 = 0,
/// OUTFROMPERI [8:8]
/// output signal from selected peripheral, before register override is applied
OUTFROMPERI: u1 = 0,
/// OUTTOPAD [9:9]
/// output signal to pad after register override is applied
OUTTOPAD: u1 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEFROMPERI [12:12]
/// output enable from selected peripheral, before register override is applied
OEFROMPERI: u1 = 0,
/// OETOPAD [13:13]
/// output enable to pad after register override is applied
OETOPAD: u1 = 0,
/// unused [14:16]
_unused14: u2 = 0,
_unused16: u1 = 0,
/// INFROMPAD [17:17]
/// input signal from pad, before override is applied
INFROMPAD: u1 = 0,
/// unused [18:18]
_unused18: u1 = 0,
/// INTOPERI [19:19]
/// input signal to peripheral, after override is applied
INTOPERI: u1 = 0,
/// unused [20:23]
_unused20: u4 = 0,
/// IRQFROMPAD [24:24]
/// interrupt from pad before override is applied
IRQFROMPAD: u1 = 0,
/// unused [25:25]
_unused25: u1 = 0,
/// IRQTOPROC [26:26]
/// interrupt to processors, after override is applied
IRQTOPROC: u1 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// GPIO status
pub const GPIO18_STATUS = Register(GPIO18_STATUS_val).init(base_address + 0x90);

/// GPIO17_CTRL
const GPIO17_CTRL_val = packed struct {
/// FUNCSEL [0:4]
/// 0-31 -&gt; selects pin function according to the gpio table\n
FUNCSEL: u5 = 31,
/// unused [5:7]
_unused5: u3 = 0,
/// OUTOVER [8:9]
/// No description
OUTOVER: u2 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEOVER [12:13]
/// No description
OEOVER: u2 = 0,
/// unused [14:15]
_unused14: u2 = 0,
/// INOVER [16:17]
/// No description
INOVER: u2 = 0,
/// unused [18:27]
_unused18: u6 = 0,
_unused24: u4 = 0,
/// IRQOVER [28:29]
/// No description
IRQOVER: u2 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// GPIO control including function select and overrides.
pub const GPIO17_CTRL = Register(GPIO17_CTRL_val).init(base_address + 0x8c);

/// GPIO17_STATUS
const GPIO17_STATUS_val = packed struct {
/// unused [0:7]
_unused0: u8 = 0,
/// OUTFROMPERI [8:8]
/// output signal from selected peripheral, before register override is applied
OUTFROMPERI: u1 = 0,
/// OUTTOPAD [9:9]
/// output signal to pad after register override is applied
OUTTOPAD: u1 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEFROMPERI [12:12]
/// output enable from selected peripheral, before register override is applied
OEFROMPERI: u1 = 0,
/// OETOPAD [13:13]
/// output enable to pad after register override is applied
OETOPAD: u1 = 0,
/// unused [14:16]
_unused14: u2 = 0,
_unused16: u1 = 0,
/// INFROMPAD [17:17]
/// input signal from pad, before override is applied
INFROMPAD: u1 = 0,
/// unused [18:18]
_unused18: u1 = 0,
/// INTOPERI [19:19]
/// input signal to peripheral, after override is applied
INTOPERI: u1 = 0,
/// unused [20:23]
_unused20: u4 = 0,
/// IRQFROMPAD [24:24]
/// interrupt from pad before override is applied
IRQFROMPAD: u1 = 0,
/// unused [25:25]
_unused25: u1 = 0,
/// IRQTOPROC [26:26]
/// interrupt to processors, after override is applied
IRQTOPROC: u1 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// GPIO status
pub const GPIO17_STATUS = Register(GPIO17_STATUS_val).init(base_address + 0x88);

/// GPIO16_CTRL
const GPIO16_CTRL_val = packed struct {
/// FUNCSEL [0:4]
/// 0-31 -&gt; selects pin function according to the gpio table\n
FUNCSEL: u5 = 31,
/// unused [5:7]
_unused5: u3 = 0,
/// OUTOVER [8:9]
/// No description
OUTOVER: u2 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEOVER [12:13]
/// No description
OEOVER: u2 = 0,
/// unused [14:15]
_unused14: u2 = 0,
/// INOVER [16:17]
/// No description
INOVER: u2 = 0,
/// unused [18:27]
_unused18: u6 = 0,
_unused24: u4 = 0,
/// IRQOVER [28:29]
/// No description
IRQOVER: u2 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// GPIO control including function select and overrides.
pub const GPIO16_CTRL = Register(GPIO16_CTRL_val).init(base_address + 0x84);

/// GPIO16_STATUS
const GPIO16_STATUS_val = packed struct {
/// unused [0:7]
_unused0: u8 = 0,
/// OUTFROMPERI [8:8]
/// output signal from selected peripheral, before register override is applied
OUTFROMPERI: u1 = 0,
/// OUTTOPAD [9:9]
/// output signal to pad after register override is applied
OUTTOPAD: u1 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEFROMPERI [12:12]
/// output enable from selected peripheral, before register override is applied
OEFROMPERI: u1 = 0,
/// OETOPAD [13:13]
/// output enable to pad after register override is applied
OETOPAD: u1 = 0,
/// unused [14:16]
_unused14: u2 = 0,
_unused16: u1 = 0,
/// INFROMPAD [17:17]
/// input signal from pad, before override is applied
INFROMPAD: u1 = 0,
/// unused [18:18]
_unused18: u1 = 0,
/// INTOPERI [19:19]
/// input signal to peripheral, after override is applied
INTOPERI: u1 = 0,
/// unused [20:23]
_unused20: u4 = 0,
/// IRQFROMPAD [24:24]
/// interrupt from pad before override is applied
IRQFROMPAD: u1 = 0,
/// unused [25:25]
_unused25: u1 = 0,
/// IRQTOPROC [26:26]
/// interrupt to processors, after override is applied
IRQTOPROC: u1 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// GPIO status
pub const GPIO16_STATUS = Register(GPIO16_STATUS_val).init(base_address + 0x80);

/// GPIO15_CTRL
const GPIO15_CTRL_val = packed struct {
/// FUNCSEL [0:4]
/// 0-31 -&gt; selects pin function according to the gpio table\n
FUNCSEL: u5 = 31,
/// unused [5:7]
_unused5: u3 = 0,
/// OUTOVER [8:9]
/// No description
OUTOVER: u2 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEOVER [12:13]
/// No description
OEOVER: u2 = 0,
/// unused [14:15]
_unused14: u2 = 0,
/// INOVER [16:17]
/// No description
INOVER: u2 = 0,
/// unused [18:27]
_unused18: u6 = 0,
_unused24: u4 = 0,
/// IRQOVER [28:29]
/// No description
IRQOVER: u2 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// GPIO control including function select and overrides.
pub const GPIO15_CTRL = Register(GPIO15_CTRL_val).init(base_address + 0x7c);

/// GPIO15_STATUS
const GPIO15_STATUS_val = packed struct {
/// unused [0:7]
_unused0: u8 = 0,
/// OUTFROMPERI [8:8]
/// output signal from selected peripheral, before register override is applied
OUTFROMPERI: u1 = 0,
/// OUTTOPAD [9:9]
/// output signal to pad after register override is applied
OUTTOPAD: u1 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEFROMPERI [12:12]
/// output enable from selected peripheral, before register override is applied
OEFROMPERI: u1 = 0,
/// OETOPAD [13:13]
/// output enable to pad after register override is applied
OETOPAD: u1 = 0,
/// unused [14:16]
_unused14: u2 = 0,
_unused16: u1 = 0,
/// INFROMPAD [17:17]
/// input signal from pad, before override is applied
INFROMPAD: u1 = 0,
/// unused [18:18]
_unused18: u1 = 0,
/// INTOPERI [19:19]
/// input signal to peripheral, after override is applied
INTOPERI: u1 = 0,
/// unused [20:23]
_unused20: u4 = 0,
/// IRQFROMPAD [24:24]
/// interrupt from pad before override is applied
IRQFROMPAD: u1 = 0,
/// unused [25:25]
_unused25: u1 = 0,
/// IRQTOPROC [26:26]
/// interrupt to processors, after override is applied
IRQTOPROC: u1 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// GPIO status
pub const GPIO15_STATUS = Register(GPIO15_STATUS_val).init(base_address + 0x78);

/// GPIO14_CTRL
const GPIO14_CTRL_val = packed struct {
/// FUNCSEL [0:4]
/// 0-31 -&gt; selects pin function according to the gpio table\n
FUNCSEL: u5 = 31,
/// unused [5:7]
_unused5: u3 = 0,
/// OUTOVER [8:9]
/// No description
OUTOVER: u2 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEOVER [12:13]
/// No description
OEOVER: u2 = 0,
/// unused [14:15]
_unused14: u2 = 0,
/// INOVER [16:17]
/// No description
INOVER: u2 = 0,
/// unused [18:27]
_unused18: u6 = 0,
_unused24: u4 = 0,
/// IRQOVER [28:29]
/// No description
IRQOVER: u2 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// GPIO control including function select and overrides.
pub const GPIO14_CTRL = Register(GPIO14_CTRL_val).init(base_address + 0x74);

/// GPIO14_STATUS
const GPIO14_STATUS_val = packed struct {
/// unused [0:7]
_unused0: u8 = 0,
/// OUTFROMPERI [8:8]
/// output signal from selected peripheral, before register override is applied
OUTFROMPERI: u1 = 0,
/// OUTTOPAD [9:9]
/// output signal to pad after register override is applied
OUTTOPAD: u1 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEFROMPERI [12:12]
/// output enable from selected peripheral, before register override is applied
OEFROMPERI: u1 = 0,
/// OETOPAD [13:13]
/// output enable to pad after register override is applied
OETOPAD: u1 = 0,
/// unused [14:16]
_unused14: u2 = 0,
_unused16: u1 = 0,
/// INFROMPAD [17:17]
/// input signal from pad, before override is applied
INFROMPAD: u1 = 0,
/// unused [18:18]
_unused18: u1 = 0,
/// INTOPERI [19:19]
/// input signal to peripheral, after override is applied
INTOPERI: u1 = 0,
/// unused [20:23]
_unused20: u4 = 0,
/// IRQFROMPAD [24:24]
/// interrupt from pad before override is applied
IRQFROMPAD: u1 = 0,
/// unused [25:25]
_unused25: u1 = 0,
/// IRQTOPROC [26:26]
/// interrupt to processors, after override is applied
IRQTOPROC: u1 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// GPIO status
pub const GPIO14_STATUS = Register(GPIO14_STATUS_val).init(base_address + 0x70);

/// GPIO13_CTRL
const GPIO13_CTRL_val = packed struct {
/// FUNCSEL [0:4]
/// 0-31 -&gt; selects pin function according to the gpio table\n
FUNCSEL: u5 = 31,
/// unused [5:7]
_unused5: u3 = 0,
/// OUTOVER [8:9]
/// No description
OUTOVER: u2 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEOVER [12:13]
/// No description
OEOVER: u2 = 0,
/// unused [14:15]
_unused14: u2 = 0,
/// INOVER [16:17]
/// No description
INOVER: u2 = 0,
/// unused [18:27]
_unused18: u6 = 0,
_unused24: u4 = 0,
/// IRQOVER [28:29]
/// No description
IRQOVER: u2 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// GPIO control including function select and overrides.
pub const GPIO13_CTRL = Register(GPIO13_CTRL_val).init(base_address + 0x6c);

/// GPIO13_STATUS
const GPIO13_STATUS_val = packed struct {
/// unused [0:7]
_unused0: u8 = 0,
/// OUTFROMPERI [8:8]
/// output signal from selected peripheral, before register override is applied
OUTFROMPERI: u1 = 0,
/// OUTTOPAD [9:9]
/// output signal to pad after register override is applied
OUTTOPAD: u1 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEFROMPERI [12:12]
/// output enable from selected peripheral, before register override is applied
OEFROMPERI: u1 = 0,
/// OETOPAD [13:13]
/// output enable to pad after register override is applied
OETOPAD: u1 = 0,
/// unused [14:16]
_unused14: u2 = 0,
_unused16: u1 = 0,
/// INFROMPAD [17:17]
/// input signal from pad, before override is applied
INFROMPAD: u1 = 0,
/// unused [18:18]
_unused18: u1 = 0,
/// INTOPERI [19:19]
/// input signal to peripheral, after override is applied
INTOPERI: u1 = 0,
/// unused [20:23]
_unused20: u4 = 0,
/// IRQFROMPAD [24:24]
/// interrupt from pad before override is applied
IRQFROMPAD: u1 = 0,
/// unused [25:25]
_unused25: u1 = 0,
/// IRQTOPROC [26:26]
/// interrupt to processors, after override is applied
IRQTOPROC: u1 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// GPIO status
pub const GPIO13_STATUS = Register(GPIO13_STATUS_val).init(base_address + 0x68);

/// GPIO12_CTRL
const GPIO12_CTRL_val = packed struct {
/// FUNCSEL [0:4]
/// 0-31 -&gt; selects pin function according to the gpio table\n
FUNCSEL: u5 = 31,
/// unused [5:7]
_unused5: u3 = 0,
/// OUTOVER [8:9]
/// No description
OUTOVER: u2 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEOVER [12:13]
/// No description
OEOVER: u2 = 0,
/// unused [14:15]
_unused14: u2 = 0,
/// INOVER [16:17]
/// No description
INOVER: u2 = 0,
/// unused [18:27]
_unused18: u6 = 0,
_unused24: u4 = 0,
/// IRQOVER [28:29]
/// No description
IRQOVER: u2 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// GPIO control including function select and overrides.
pub const GPIO12_CTRL = Register(GPIO12_CTRL_val).init(base_address + 0x64);

/// GPIO12_STATUS
const GPIO12_STATUS_val = packed struct {
/// unused [0:7]
_unused0: u8 = 0,
/// OUTFROMPERI [8:8]
/// output signal from selected peripheral, before register override is applied
OUTFROMPERI: u1 = 0,
/// OUTTOPAD [9:9]
/// output signal to pad after register override is applied
OUTTOPAD: u1 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEFROMPERI [12:12]
/// output enable from selected peripheral, before register override is applied
OEFROMPERI: u1 = 0,
/// OETOPAD [13:13]
/// output enable to pad after register override is applied
OETOPAD: u1 = 0,
/// unused [14:16]
_unused14: u2 = 0,
_unused16: u1 = 0,
/// INFROMPAD [17:17]
/// input signal from pad, before override is applied
INFROMPAD: u1 = 0,
/// unused [18:18]
_unused18: u1 = 0,
/// INTOPERI [19:19]
/// input signal to peripheral, after override is applied
INTOPERI: u1 = 0,
/// unused [20:23]
_unused20: u4 = 0,
/// IRQFROMPAD [24:24]
/// interrupt from pad before override is applied
IRQFROMPAD: u1 = 0,
/// unused [25:25]
_unused25: u1 = 0,
/// IRQTOPROC [26:26]
/// interrupt to processors, after override is applied
IRQTOPROC: u1 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// GPIO status
pub const GPIO12_STATUS = Register(GPIO12_STATUS_val).init(base_address + 0x60);

/// GPIO11_CTRL
const GPIO11_CTRL_val = packed struct {
/// FUNCSEL [0:4]
/// 0-31 -&gt; selects pin function according to the gpio table\n
FUNCSEL: u5 = 31,
/// unused [5:7]
_unused5: u3 = 0,
/// OUTOVER [8:9]
/// No description
OUTOVER: u2 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEOVER [12:13]
/// No description
OEOVER: u2 = 0,
/// unused [14:15]
_unused14: u2 = 0,
/// INOVER [16:17]
/// No description
INOVER: u2 = 0,
/// unused [18:27]
_unused18: u6 = 0,
_unused24: u4 = 0,
/// IRQOVER [28:29]
/// No description
IRQOVER: u2 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// GPIO control including function select and overrides.
pub const GPIO11_CTRL = Register(GPIO11_CTRL_val).init(base_address + 0x5c);

/// GPIO11_STATUS
const GPIO11_STATUS_val = packed struct {
/// unused [0:7]
_unused0: u8 = 0,
/// OUTFROMPERI [8:8]
/// output signal from selected peripheral, before register override is applied
OUTFROMPERI: u1 = 0,
/// OUTTOPAD [9:9]
/// output signal to pad after register override is applied
OUTTOPAD: u1 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEFROMPERI [12:12]
/// output enable from selected peripheral, before register override is applied
OEFROMPERI: u1 = 0,
/// OETOPAD [13:13]
/// output enable to pad after register override is applied
OETOPAD: u1 = 0,
/// unused [14:16]
_unused14: u2 = 0,
_unused16: u1 = 0,
/// INFROMPAD [17:17]
/// input signal from pad, before override is applied
INFROMPAD: u1 = 0,
/// unused [18:18]
_unused18: u1 = 0,
/// INTOPERI [19:19]
/// input signal to peripheral, after override is applied
INTOPERI: u1 = 0,
/// unused [20:23]
_unused20: u4 = 0,
/// IRQFROMPAD [24:24]
/// interrupt from pad before override is applied
IRQFROMPAD: u1 = 0,
/// unused [25:25]
_unused25: u1 = 0,
/// IRQTOPROC [26:26]
/// interrupt to processors, after override is applied
IRQTOPROC: u1 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// GPIO status
pub const GPIO11_STATUS = Register(GPIO11_STATUS_val).init(base_address + 0x58);

/// GPIO10_CTRL
const GPIO10_CTRL_val = packed struct {
/// FUNCSEL [0:4]
/// 0-31 -&gt; selects pin function according to the gpio table\n
FUNCSEL: u5 = 31,
/// unused [5:7]
_unused5: u3 = 0,
/// OUTOVER [8:9]
/// No description
OUTOVER: u2 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEOVER [12:13]
/// No description
OEOVER: u2 = 0,
/// unused [14:15]
_unused14: u2 = 0,
/// INOVER [16:17]
/// No description
INOVER: u2 = 0,
/// unused [18:27]
_unused18: u6 = 0,
_unused24: u4 = 0,
/// IRQOVER [28:29]
/// No description
IRQOVER: u2 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// GPIO control including function select and overrides.
pub const GPIO10_CTRL = Register(GPIO10_CTRL_val).init(base_address + 0x54);

/// GPIO10_STATUS
const GPIO10_STATUS_val = packed struct {
/// unused [0:7]
_unused0: u8 = 0,
/// OUTFROMPERI [8:8]
/// output signal from selected peripheral, before register override is applied
OUTFROMPERI: u1 = 0,
/// OUTTOPAD [9:9]
/// output signal to pad after register override is applied
OUTTOPAD: u1 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEFROMPERI [12:12]
/// output enable from selected peripheral, before register override is applied
OEFROMPERI: u1 = 0,
/// OETOPAD [13:13]
/// output enable to pad after register override is applied
OETOPAD: u1 = 0,
/// unused [14:16]
_unused14: u2 = 0,
_unused16: u1 = 0,
/// INFROMPAD [17:17]
/// input signal from pad, before override is applied
INFROMPAD: u1 = 0,
/// unused [18:18]
_unused18: u1 = 0,
/// INTOPERI [19:19]
/// input signal to peripheral, after override is applied
INTOPERI: u1 = 0,
/// unused [20:23]
_unused20: u4 = 0,
/// IRQFROMPAD [24:24]
/// interrupt from pad before override is applied
IRQFROMPAD: u1 = 0,
/// unused [25:25]
_unused25: u1 = 0,
/// IRQTOPROC [26:26]
/// interrupt to processors, after override is applied
IRQTOPROC: u1 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// GPIO status
pub const GPIO10_STATUS = Register(GPIO10_STATUS_val).init(base_address + 0x50);

/// GPIO9_CTRL
const GPIO9_CTRL_val = packed struct {
/// FUNCSEL [0:4]
/// 0-31 -&gt; selects pin function according to the gpio table\n
FUNCSEL: u5 = 31,
/// unused [5:7]
_unused5: u3 = 0,
/// OUTOVER [8:9]
/// No description
OUTOVER: u2 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEOVER [12:13]
/// No description
OEOVER: u2 = 0,
/// unused [14:15]
_unused14: u2 = 0,
/// INOVER [16:17]
/// No description
INOVER: u2 = 0,
/// unused [18:27]
_unused18: u6 = 0,
_unused24: u4 = 0,
/// IRQOVER [28:29]
/// No description
IRQOVER: u2 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// GPIO control including function select and overrides.
pub const GPIO9_CTRL = Register(GPIO9_CTRL_val).init(base_address + 0x4c);

/// GPIO9_STATUS
const GPIO9_STATUS_val = packed struct {
/// unused [0:7]
_unused0: u8 = 0,
/// OUTFROMPERI [8:8]
/// output signal from selected peripheral, before register override is applied
OUTFROMPERI: u1 = 0,
/// OUTTOPAD [9:9]
/// output signal to pad after register override is applied
OUTTOPAD: u1 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEFROMPERI [12:12]
/// output enable from selected peripheral, before register override is applied
OEFROMPERI: u1 = 0,
/// OETOPAD [13:13]
/// output enable to pad after register override is applied
OETOPAD: u1 = 0,
/// unused [14:16]
_unused14: u2 = 0,
_unused16: u1 = 0,
/// INFROMPAD [17:17]
/// input signal from pad, before override is applied
INFROMPAD: u1 = 0,
/// unused [18:18]
_unused18: u1 = 0,
/// INTOPERI [19:19]
/// input signal to peripheral, after override is applied
INTOPERI: u1 = 0,
/// unused [20:23]
_unused20: u4 = 0,
/// IRQFROMPAD [24:24]
/// interrupt from pad before override is applied
IRQFROMPAD: u1 = 0,
/// unused [25:25]
_unused25: u1 = 0,
/// IRQTOPROC [26:26]
/// interrupt to processors, after override is applied
IRQTOPROC: u1 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// GPIO status
pub const GPIO9_STATUS = Register(GPIO9_STATUS_val).init(base_address + 0x48);

/// GPIO8_CTRL
const GPIO8_CTRL_val = packed struct {
/// FUNCSEL [0:4]
/// 0-31 -&gt; selects pin function according to the gpio table\n
FUNCSEL: u5 = 31,
/// unused [5:7]
_unused5: u3 = 0,
/// OUTOVER [8:9]
/// No description
OUTOVER: u2 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEOVER [12:13]
/// No description
OEOVER: u2 = 0,
/// unused [14:15]
_unused14: u2 = 0,
/// INOVER [16:17]
/// No description
INOVER: u2 = 0,
/// unused [18:27]
_unused18: u6 = 0,
_unused24: u4 = 0,
/// IRQOVER [28:29]
/// No description
IRQOVER: u2 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// GPIO control including function select and overrides.
pub const GPIO8_CTRL = Register(GPIO8_CTRL_val).init(base_address + 0x44);

/// GPIO8_STATUS
const GPIO8_STATUS_val = packed struct {
/// unused [0:7]
_unused0: u8 = 0,
/// OUTFROMPERI [8:8]
/// output signal from selected peripheral, before register override is applied
OUTFROMPERI: u1 = 0,
/// OUTTOPAD [9:9]
/// output signal to pad after register override is applied
OUTTOPAD: u1 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEFROMPERI [12:12]
/// output enable from selected peripheral, before register override is applied
OEFROMPERI: u1 = 0,
/// OETOPAD [13:13]
/// output enable to pad after register override is applied
OETOPAD: u1 = 0,
/// unused [14:16]
_unused14: u2 = 0,
_unused16: u1 = 0,
/// INFROMPAD [17:17]
/// input signal from pad, before override is applied
INFROMPAD: u1 = 0,
/// unused [18:18]
_unused18: u1 = 0,
/// INTOPERI [19:19]
/// input signal to peripheral, after override is applied
INTOPERI: u1 = 0,
/// unused [20:23]
_unused20: u4 = 0,
/// IRQFROMPAD [24:24]
/// interrupt from pad before override is applied
IRQFROMPAD: u1 = 0,
/// unused [25:25]
_unused25: u1 = 0,
/// IRQTOPROC [26:26]
/// interrupt to processors, after override is applied
IRQTOPROC: u1 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// GPIO status
pub const GPIO8_STATUS = Register(GPIO8_STATUS_val).init(base_address + 0x40);

/// GPIO7_CTRL
const GPIO7_CTRL_val = packed struct {
/// FUNCSEL [0:4]
/// 0-31 -&gt; selects pin function according to the gpio table\n
FUNCSEL: u5 = 31,
/// unused [5:7]
_unused5: u3 = 0,
/// OUTOVER [8:9]
/// No description
OUTOVER: u2 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEOVER [12:13]
/// No description
OEOVER: u2 = 0,
/// unused [14:15]
_unused14: u2 = 0,
/// INOVER [16:17]
/// No description
INOVER: u2 = 0,
/// unused [18:27]
_unused18: u6 = 0,
_unused24: u4 = 0,
/// IRQOVER [28:29]
/// No description
IRQOVER: u2 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// GPIO control including function select and overrides.
pub const GPIO7_CTRL = Register(GPIO7_CTRL_val).init(base_address + 0x3c);

/// GPIO7_STATUS
const GPIO7_STATUS_val = packed struct {
/// unused [0:7]
_unused0: u8 = 0,
/// OUTFROMPERI [8:8]
/// output signal from selected peripheral, before register override is applied
OUTFROMPERI: u1 = 0,
/// OUTTOPAD [9:9]
/// output signal to pad after register override is applied
OUTTOPAD: u1 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEFROMPERI [12:12]
/// output enable from selected peripheral, before register override is applied
OEFROMPERI: u1 = 0,
/// OETOPAD [13:13]
/// output enable to pad after register override is applied
OETOPAD: u1 = 0,
/// unused [14:16]
_unused14: u2 = 0,
_unused16: u1 = 0,
/// INFROMPAD [17:17]
/// input signal from pad, before override is applied
INFROMPAD: u1 = 0,
/// unused [18:18]
_unused18: u1 = 0,
/// INTOPERI [19:19]
/// input signal to peripheral, after override is applied
INTOPERI: u1 = 0,
/// unused [20:23]
_unused20: u4 = 0,
/// IRQFROMPAD [24:24]
/// interrupt from pad before override is applied
IRQFROMPAD: u1 = 0,
/// unused [25:25]
_unused25: u1 = 0,
/// IRQTOPROC [26:26]
/// interrupt to processors, after override is applied
IRQTOPROC: u1 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// GPIO status
pub const GPIO7_STATUS = Register(GPIO7_STATUS_val).init(base_address + 0x38);

/// GPIO6_CTRL
const GPIO6_CTRL_val = packed struct {
/// FUNCSEL [0:4]
/// 0-31 -&gt; selects pin function according to the gpio table\n
FUNCSEL: u5 = 31,
/// unused [5:7]
_unused5: u3 = 0,
/// OUTOVER [8:9]
/// No description
OUTOVER: u2 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEOVER [12:13]
/// No description
OEOVER: u2 = 0,
/// unused [14:15]
_unused14: u2 = 0,
/// INOVER [16:17]
/// No description
INOVER: u2 = 0,
/// unused [18:27]
_unused18: u6 = 0,
_unused24: u4 = 0,
/// IRQOVER [28:29]
/// No description
IRQOVER: u2 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// GPIO control including function select and overrides.
pub const GPIO6_CTRL = Register(GPIO6_CTRL_val).init(base_address + 0x34);

/// GPIO6_STATUS
const GPIO6_STATUS_val = packed struct {
/// unused [0:7]
_unused0: u8 = 0,
/// OUTFROMPERI [8:8]
/// output signal from selected peripheral, before register override is applied
OUTFROMPERI: u1 = 0,
/// OUTTOPAD [9:9]
/// output signal to pad after register override is applied
OUTTOPAD: u1 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEFROMPERI [12:12]
/// output enable from selected peripheral, before register override is applied
OEFROMPERI: u1 = 0,
/// OETOPAD [13:13]
/// output enable to pad after register override is applied
OETOPAD: u1 = 0,
/// unused [14:16]
_unused14: u2 = 0,
_unused16: u1 = 0,
/// INFROMPAD [17:17]
/// input signal from pad, before override is applied
INFROMPAD: u1 = 0,
/// unused [18:18]
_unused18: u1 = 0,
/// INTOPERI [19:19]
/// input signal to peripheral, after override is applied
INTOPERI: u1 = 0,
/// unused [20:23]
_unused20: u4 = 0,
/// IRQFROMPAD [24:24]
/// interrupt from pad before override is applied
IRQFROMPAD: u1 = 0,
/// unused [25:25]
_unused25: u1 = 0,
/// IRQTOPROC [26:26]
/// interrupt to processors, after override is applied
IRQTOPROC: u1 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// GPIO status
pub const GPIO6_STATUS = Register(GPIO6_STATUS_val).init(base_address + 0x30);

/// GPIO5_CTRL
const GPIO5_CTRL_val = packed struct {
/// FUNCSEL [0:4]
/// 0-31 -&gt; selects pin function according to the gpio table\n
FUNCSEL: u5 = 31,
/// unused [5:7]
_unused5: u3 = 0,
/// OUTOVER [8:9]
/// No description
OUTOVER: u2 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEOVER [12:13]
/// No description
OEOVER: u2 = 0,
/// unused [14:15]
_unused14: u2 = 0,
/// INOVER [16:17]
/// No description
INOVER: u2 = 0,
/// unused [18:27]
_unused18: u6 = 0,
_unused24: u4 = 0,
/// IRQOVER [28:29]
/// No description
IRQOVER: u2 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// GPIO control including function select and overrides.
pub const GPIO5_CTRL = Register(GPIO5_CTRL_val).init(base_address + 0x2c);

/// GPIO5_STATUS
const GPIO5_STATUS_val = packed struct {
/// unused [0:7]
_unused0: u8 = 0,
/// OUTFROMPERI [8:8]
/// output signal from selected peripheral, before register override is applied
OUTFROMPERI: u1 = 0,
/// OUTTOPAD [9:9]
/// output signal to pad after register override is applied
OUTTOPAD: u1 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEFROMPERI [12:12]
/// output enable from selected peripheral, before register override is applied
OEFROMPERI: u1 = 0,
/// OETOPAD [13:13]
/// output enable to pad after register override is applied
OETOPAD: u1 = 0,
/// unused [14:16]
_unused14: u2 = 0,
_unused16: u1 = 0,
/// INFROMPAD [17:17]
/// input signal from pad, before override is applied
INFROMPAD: u1 = 0,
/// unused [18:18]
_unused18: u1 = 0,
/// INTOPERI [19:19]
/// input signal to peripheral, after override is applied
INTOPERI: u1 = 0,
/// unused [20:23]
_unused20: u4 = 0,
/// IRQFROMPAD [24:24]
/// interrupt from pad before override is applied
IRQFROMPAD: u1 = 0,
/// unused [25:25]
_unused25: u1 = 0,
/// IRQTOPROC [26:26]
/// interrupt to processors, after override is applied
IRQTOPROC: u1 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// GPIO status
pub const GPIO5_STATUS = Register(GPIO5_STATUS_val).init(base_address + 0x28);

/// GPIO4_CTRL
const GPIO4_CTRL_val = packed struct {
/// FUNCSEL [0:4]
/// 0-31 -&gt; selects pin function according to the gpio table\n
FUNCSEL: u5 = 31,
/// unused [5:7]
_unused5: u3 = 0,
/// OUTOVER [8:9]
/// No description
OUTOVER: u2 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEOVER [12:13]
/// No description
OEOVER: u2 = 0,
/// unused [14:15]
_unused14: u2 = 0,
/// INOVER [16:17]
/// No description
INOVER: u2 = 0,
/// unused [18:27]
_unused18: u6 = 0,
_unused24: u4 = 0,
/// IRQOVER [28:29]
/// No description
IRQOVER: u2 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// GPIO control including function select and overrides.
pub const GPIO4_CTRL = Register(GPIO4_CTRL_val).init(base_address + 0x24);

/// GPIO4_STATUS
const GPIO4_STATUS_val = packed struct {
/// unused [0:7]
_unused0: u8 = 0,
/// OUTFROMPERI [8:8]
/// output signal from selected peripheral, before register override is applied
OUTFROMPERI: u1 = 0,
/// OUTTOPAD [9:9]
/// output signal to pad after register override is applied
OUTTOPAD: u1 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEFROMPERI [12:12]
/// output enable from selected peripheral, before register override is applied
OEFROMPERI: u1 = 0,
/// OETOPAD [13:13]
/// output enable to pad after register override is applied
OETOPAD: u1 = 0,
/// unused [14:16]
_unused14: u2 = 0,
_unused16: u1 = 0,
/// INFROMPAD [17:17]
/// input signal from pad, before override is applied
INFROMPAD: u1 = 0,
/// unused [18:18]
_unused18: u1 = 0,
/// INTOPERI [19:19]
/// input signal to peripheral, after override is applied
INTOPERI: u1 = 0,
/// unused [20:23]
_unused20: u4 = 0,
/// IRQFROMPAD [24:24]
/// interrupt from pad before override is applied
IRQFROMPAD: u1 = 0,
/// unused [25:25]
_unused25: u1 = 0,
/// IRQTOPROC [26:26]
/// interrupt to processors, after override is applied
IRQTOPROC: u1 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// GPIO status
pub const GPIO4_STATUS = Register(GPIO4_STATUS_val).init(base_address + 0x20);

/// GPIO3_CTRL
const GPIO3_CTRL_val = packed struct {
/// FUNCSEL [0:4]
/// 0-31 -&gt; selects pin function according to the gpio table\n
FUNCSEL: u5 = 31,
/// unused [5:7]
_unused5: u3 = 0,
/// OUTOVER [8:9]
/// No description
OUTOVER: u2 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEOVER [12:13]
/// No description
OEOVER: u2 = 0,
/// unused [14:15]
_unused14: u2 = 0,
/// INOVER [16:17]
/// No description
INOVER: u2 = 0,
/// unused [18:27]
_unused18: u6 = 0,
_unused24: u4 = 0,
/// IRQOVER [28:29]
/// No description
IRQOVER: u2 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// GPIO control including function select and overrides.
pub const GPIO3_CTRL = Register(GPIO3_CTRL_val).init(base_address + 0x1c);

/// GPIO3_STATUS
const GPIO3_STATUS_val = packed struct {
/// unused [0:7]
_unused0: u8 = 0,
/// OUTFROMPERI [8:8]
/// output signal from selected peripheral, before register override is applied
OUTFROMPERI: u1 = 0,
/// OUTTOPAD [9:9]
/// output signal to pad after register override is applied
OUTTOPAD: u1 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEFROMPERI [12:12]
/// output enable from selected peripheral, before register override is applied
OEFROMPERI: u1 = 0,
/// OETOPAD [13:13]
/// output enable to pad after register override is applied
OETOPAD: u1 = 0,
/// unused [14:16]
_unused14: u2 = 0,
_unused16: u1 = 0,
/// INFROMPAD [17:17]
/// input signal from pad, before override is applied
INFROMPAD: u1 = 0,
/// unused [18:18]
_unused18: u1 = 0,
/// INTOPERI [19:19]
/// input signal to peripheral, after override is applied
INTOPERI: u1 = 0,
/// unused [20:23]
_unused20: u4 = 0,
/// IRQFROMPAD [24:24]
/// interrupt from pad before override is applied
IRQFROMPAD: u1 = 0,
/// unused [25:25]
_unused25: u1 = 0,
/// IRQTOPROC [26:26]
/// interrupt to processors, after override is applied
IRQTOPROC: u1 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// GPIO status
pub const GPIO3_STATUS = Register(GPIO3_STATUS_val).init(base_address + 0x18);

/// GPIO2_CTRL
const GPIO2_CTRL_val = packed struct {
/// FUNCSEL [0:4]
/// 0-31 -&gt; selects pin function according to the gpio table\n
FUNCSEL: u5 = 31,
/// unused [5:7]
_unused5: u3 = 0,
/// OUTOVER [8:9]
/// No description
OUTOVER: u2 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEOVER [12:13]
/// No description
OEOVER: u2 = 0,
/// unused [14:15]
_unused14: u2 = 0,
/// INOVER [16:17]
/// No description
INOVER: u2 = 0,
/// unused [18:27]
_unused18: u6 = 0,
_unused24: u4 = 0,
/// IRQOVER [28:29]
/// No description
IRQOVER: u2 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// GPIO control including function select and overrides.
pub const GPIO2_CTRL = Register(GPIO2_CTRL_val).init(base_address + 0x14);

/// GPIO2_STATUS
const GPIO2_STATUS_val = packed struct {
/// unused [0:7]
_unused0: u8 = 0,
/// OUTFROMPERI [8:8]
/// output signal from selected peripheral, before register override is applied
OUTFROMPERI: u1 = 0,
/// OUTTOPAD [9:9]
/// output signal to pad after register override is applied
OUTTOPAD: u1 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEFROMPERI [12:12]
/// output enable from selected peripheral, before register override is applied
OEFROMPERI: u1 = 0,
/// OETOPAD [13:13]
/// output enable to pad after register override is applied
OETOPAD: u1 = 0,
/// unused [14:16]
_unused14: u2 = 0,
_unused16: u1 = 0,
/// INFROMPAD [17:17]
/// input signal from pad, before override is applied
INFROMPAD: u1 = 0,
/// unused [18:18]
_unused18: u1 = 0,
/// INTOPERI [19:19]
/// input signal to peripheral, after override is applied
INTOPERI: u1 = 0,
/// unused [20:23]
_unused20: u4 = 0,
/// IRQFROMPAD [24:24]
/// interrupt from pad before override is applied
IRQFROMPAD: u1 = 0,
/// unused [25:25]
_unused25: u1 = 0,
/// IRQTOPROC [26:26]
/// interrupt to processors, after override is applied
IRQTOPROC: u1 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// GPIO status
pub const GPIO2_STATUS = Register(GPIO2_STATUS_val).init(base_address + 0x10);

/// GPIO1_CTRL
const GPIO1_CTRL_val = packed struct {
/// FUNCSEL [0:4]
/// 0-31 -&gt; selects pin function according to the gpio table\n
FUNCSEL: u5 = 31,
/// unused [5:7]
_unused5: u3 = 0,
/// OUTOVER [8:9]
/// No description
OUTOVER: u2 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEOVER [12:13]
/// No description
OEOVER: u2 = 0,
/// unused [14:15]
_unused14: u2 = 0,
/// INOVER [16:17]
/// No description
INOVER: u2 = 0,
/// unused [18:27]
_unused18: u6 = 0,
_unused24: u4 = 0,
/// IRQOVER [28:29]
/// No description
IRQOVER: u2 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// GPIO control including function select and overrides.
pub const GPIO1_CTRL = Register(GPIO1_CTRL_val).init(base_address + 0xc);

/// GPIO1_STATUS
const GPIO1_STATUS_val = packed struct {
/// unused [0:7]
_unused0: u8 = 0,
/// OUTFROMPERI [8:8]
/// output signal from selected peripheral, before register override is applied
OUTFROMPERI: u1 = 0,
/// OUTTOPAD [9:9]
/// output signal to pad after register override is applied
OUTTOPAD: u1 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEFROMPERI [12:12]
/// output enable from selected peripheral, before register override is applied
OEFROMPERI: u1 = 0,
/// OETOPAD [13:13]
/// output enable to pad after register override is applied
OETOPAD: u1 = 0,
/// unused [14:16]
_unused14: u2 = 0,
_unused16: u1 = 0,
/// INFROMPAD [17:17]
/// input signal from pad, before override is applied
INFROMPAD: u1 = 0,
/// unused [18:18]
_unused18: u1 = 0,
/// INTOPERI [19:19]
/// input signal to peripheral, after override is applied
INTOPERI: u1 = 0,
/// unused [20:23]
_unused20: u4 = 0,
/// IRQFROMPAD [24:24]
/// interrupt from pad before override is applied
IRQFROMPAD: u1 = 0,
/// unused [25:25]
_unused25: u1 = 0,
/// IRQTOPROC [26:26]
/// interrupt to processors, after override is applied
IRQTOPROC: u1 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// GPIO status
pub const GPIO1_STATUS = Register(GPIO1_STATUS_val).init(base_address + 0x8);

/// GPIO0_CTRL
const GPIO0_CTRL_val = packed struct {
/// FUNCSEL [0:4]
/// 0-31 -&gt; selects pin function according to the gpio table\n
FUNCSEL: u5 = 31,
/// unused [5:7]
_unused5: u3 = 0,
/// OUTOVER [8:9]
/// No description
OUTOVER: u2 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEOVER [12:13]
/// No description
OEOVER: u2 = 0,
/// unused [14:15]
_unused14: u2 = 0,
/// INOVER [16:17]
/// No description
INOVER: u2 = 0,
/// unused [18:27]
_unused18: u6 = 0,
_unused24: u4 = 0,
/// IRQOVER [28:29]
/// No description
IRQOVER: u2 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// GPIO control including function select and overrides.
pub const GPIO0_CTRL = Register(GPIO0_CTRL_val).init(base_address + 0x4);

/// GPIO0_STATUS
const GPIO0_STATUS_val = packed struct {
/// unused [0:7]
_unused0: u8 = 0,
/// OUTFROMPERI [8:8]
/// output signal from selected peripheral, before register override is applied
OUTFROMPERI: u1 = 0,
/// OUTTOPAD [9:9]
/// output signal to pad after register override is applied
OUTTOPAD: u1 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEFROMPERI [12:12]
/// output enable from selected peripheral, before register override is applied
OEFROMPERI: u1 = 0,
/// OETOPAD [13:13]
/// output enable to pad after register override is applied
OETOPAD: u1 = 0,
/// unused [14:16]
_unused14: u2 = 0,
_unused16: u1 = 0,
/// INFROMPAD [17:17]
/// input signal from pad, before override is applied
INFROMPAD: u1 = 0,
/// unused [18:18]
_unused18: u1 = 0,
/// INTOPERI [19:19]
/// input signal to peripheral, after override is applied
INTOPERI: u1 = 0,
/// unused [20:23]
_unused20: u4 = 0,
/// IRQFROMPAD [24:24]
/// interrupt from pad before override is applied
IRQFROMPAD: u1 = 0,
/// unused [25:25]
_unused25: u1 = 0,
/// IRQTOPROC [26:26]
/// interrupt to processors, after override is applied
IRQTOPROC: u1 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// GPIO status
pub const GPIO0_STATUS = Register(GPIO0_STATUS_val).init(base_address + 0x0);
};

/// No description
pub const IO_QSPI = struct {

const base_address = 0x40018000;
/// DORMANT_WAKE_INTS
const DORMANT_WAKE_INTS_val = packed struct {
/// GPIO_QSPI_SCLK_LEVEL_LOW [0:0]
/// No description
GPIO_QSPI_SCLK_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SCLK_LEVEL_HIGH [1:1]
/// No description
GPIO_QSPI_SCLK_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SCLK_EDGE_LOW [2:2]
/// No description
GPIO_QSPI_SCLK_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SCLK_EDGE_HIGH [3:3]
/// No description
GPIO_QSPI_SCLK_EDGE_HIGH: u1 = 0,
/// GPIO_QSPI_SS_LEVEL_LOW [4:4]
/// No description
GPIO_QSPI_SS_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SS_LEVEL_HIGH [5:5]
/// No description
GPIO_QSPI_SS_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SS_EDGE_LOW [6:6]
/// No description
GPIO_QSPI_SS_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SS_EDGE_HIGH [7:7]
/// No description
GPIO_QSPI_SS_EDGE_HIGH: u1 = 0,
/// GPIO_QSPI_SD0_LEVEL_LOW [8:8]
/// No description
GPIO_QSPI_SD0_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SD0_LEVEL_HIGH [9:9]
/// No description
GPIO_QSPI_SD0_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SD0_EDGE_LOW [10:10]
/// No description
GPIO_QSPI_SD0_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SD0_EDGE_HIGH [11:11]
/// No description
GPIO_QSPI_SD0_EDGE_HIGH: u1 = 0,
/// GPIO_QSPI_SD1_LEVEL_LOW [12:12]
/// No description
GPIO_QSPI_SD1_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SD1_LEVEL_HIGH [13:13]
/// No description
GPIO_QSPI_SD1_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SD1_EDGE_LOW [14:14]
/// No description
GPIO_QSPI_SD1_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SD1_EDGE_HIGH [15:15]
/// No description
GPIO_QSPI_SD1_EDGE_HIGH: u1 = 0,
/// GPIO_QSPI_SD2_LEVEL_LOW [16:16]
/// No description
GPIO_QSPI_SD2_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SD2_LEVEL_HIGH [17:17]
/// No description
GPIO_QSPI_SD2_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SD2_EDGE_LOW [18:18]
/// No description
GPIO_QSPI_SD2_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SD2_EDGE_HIGH [19:19]
/// No description
GPIO_QSPI_SD2_EDGE_HIGH: u1 = 0,
/// GPIO_QSPI_SD3_LEVEL_LOW [20:20]
/// No description
GPIO_QSPI_SD3_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SD3_LEVEL_HIGH [21:21]
/// No description
GPIO_QSPI_SD3_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SD3_EDGE_LOW [22:22]
/// No description
GPIO_QSPI_SD3_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SD3_EDGE_HIGH [23:23]
/// No description
GPIO_QSPI_SD3_EDGE_HIGH: u1 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// Interrupt status after masking &amp; forcing for dormant_wake
pub const DORMANT_WAKE_INTS = Register(DORMANT_WAKE_INTS_val).init(base_address + 0x54);

/// DORMANT_WAKE_INTF
const DORMANT_WAKE_INTF_val = packed struct {
/// GPIO_QSPI_SCLK_LEVEL_LOW [0:0]
/// No description
GPIO_QSPI_SCLK_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SCLK_LEVEL_HIGH [1:1]
/// No description
GPIO_QSPI_SCLK_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SCLK_EDGE_LOW [2:2]
/// No description
GPIO_QSPI_SCLK_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SCLK_EDGE_HIGH [3:3]
/// No description
GPIO_QSPI_SCLK_EDGE_HIGH: u1 = 0,
/// GPIO_QSPI_SS_LEVEL_LOW [4:4]
/// No description
GPIO_QSPI_SS_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SS_LEVEL_HIGH [5:5]
/// No description
GPIO_QSPI_SS_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SS_EDGE_LOW [6:6]
/// No description
GPIO_QSPI_SS_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SS_EDGE_HIGH [7:7]
/// No description
GPIO_QSPI_SS_EDGE_HIGH: u1 = 0,
/// GPIO_QSPI_SD0_LEVEL_LOW [8:8]
/// No description
GPIO_QSPI_SD0_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SD0_LEVEL_HIGH [9:9]
/// No description
GPIO_QSPI_SD0_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SD0_EDGE_LOW [10:10]
/// No description
GPIO_QSPI_SD0_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SD0_EDGE_HIGH [11:11]
/// No description
GPIO_QSPI_SD0_EDGE_HIGH: u1 = 0,
/// GPIO_QSPI_SD1_LEVEL_LOW [12:12]
/// No description
GPIO_QSPI_SD1_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SD1_LEVEL_HIGH [13:13]
/// No description
GPIO_QSPI_SD1_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SD1_EDGE_LOW [14:14]
/// No description
GPIO_QSPI_SD1_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SD1_EDGE_HIGH [15:15]
/// No description
GPIO_QSPI_SD1_EDGE_HIGH: u1 = 0,
/// GPIO_QSPI_SD2_LEVEL_LOW [16:16]
/// No description
GPIO_QSPI_SD2_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SD2_LEVEL_HIGH [17:17]
/// No description
GPIO_QSPI_SD2_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SD2_EDGE_LOW [18:18]
/// No description
GPIO_QSPI_SD2_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SD2_EDGE_HIGH [19:19]
/// No description
GPIO_QSPI_SD2_EDGE_HIGH: u1 = 0,
/// GPIO_QSPI_SD3_LEVEL_LOW [20:20]
/// No description
GPIO_QSPI_SD3_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SD3_LEVEL_HIGH [21:21]
/// No description
GPIO_QSPI_SD3_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SD3_EDGE_LOW [22:22]
/// No description
GPIO_QSPI_SD3_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SD3_EDGE_HIGH [23:23]
/// No description
GPIO_QSPI_SD3_EDGE_HIGH: u1 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// Interrupt Force for dormant_wake
pub const DORMANT_WAKE_INTF = Register(DORMANT_WAKE_INTF_val).init(base_address + 0x50);

/// DORMANT_WAKE_INTE
const DORMANT_WAKE_INTE_val = packed struct {
/// GPIO_QSPI_SCLK_LEVEL_LOW [0:0]
/// No description
GPIO_QSPI_SCLK_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SCLK_LEVEL_HIGH [1:1]
/// No description
GPIO_QSPI_SCLK_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SCLK_EDGE_LOW [2:2]
/// No description
GPIO_QSPI_SCLK_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SCLK_EDGE_HIGH [3:3]
/// No description
GPIO_QSPI_SCLK_EDGE_HIGH: u1 = 0,
/// GPIO_QSPI_SS_LEVEL_LOW [4:4]
/// No description
GPIO_QSPI_SS_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SS_LEVEL_HIGH [5:5]
/// No description
GPIO_QSPI_SS_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SS_EDGE_LOW [6:6]
/// No description
GPIO_QSPI_SS_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SS_EDGE_HIGH [7:7]
/// No description
GPIO_QSPI_SS_EDGE_HIGH: u1 = 0,
/// GPIO_QSPI_SD0_LEVEL_LOW [8:8]
/// No description
GPIO_QSPI_SD0_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SD0_LEVEL_HIGH [9:9]
/// No description
GPIO_QSPI_SD0_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SD0_EDGE_LOW [10:10]
/// No description
GPIO_QSPI_SD0_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SD0_EDGE_HIGH [11:11]
/// No description
GPIO_QSPI_SD0_EDGE_HIGH: u1 = 0,
/// GPIO_QSPI_SD1_LEVEL_LOW [12:12]
/// No description
GPIO_QSPI_SD1_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SD1_LEVEL_HIGH [13:13]
/// No description
GPIO_QSPI_SD1_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SD1_EDGE_LOW [14:14]
/// No description
GPIO_QSPI_SD1_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SD1_EDGE_HIGH [15:15]
/// No description
GPIO_QSPI_SD1_EDGE_HIGH: u1 = 0,
/// GPIO_QSPI_SD2_LEVEL_LOW [16:16]
/// No description
GPIO_QSPI_SD2_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SD2_LEVEL_HIGH [17:17]
/// No description
GPIO_QSPI_SD2_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SD2_EDGE_LOW [18:18]
/// No description
GPIO_QSPI_SD2_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SD2_EDGE_HIGH [19:19]
/// No description
GPIO_QSPI_SD2_EDGE_HIGH: u1 = 0,
/// GPIO_QSPI_SD3_LEVEL_LOW [20:20]
/// No description
GPIO_QSPI_SD3_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SD3_LEVEL_HIGH [21:21]
/// No description
GPIO_QSPI_SD3_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SD3_EDGE_LOW [22:22]
/// No description
GPIO_QSPI_SD3_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SD3_EDGE_HIGH [23:23]
/// No description
GPIO_QSPI_SD3_EDGE_HIGH: u1 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// Interrupt Enable for dormant_wake
pub const DORMANT_WAKE_INTE = Register(DORMANT_WAKE_INTE_val).init(base_address + 0x4c);

/// PROC1_INTS
const PROC1_INTS_val = packed struct {
/// GPIO_QSPI_SCLK_LEVEL_LOW [0:0]
/// No description
GPIO_QSPI_SCLK_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SCLK_LEVEL_HIGH [1:1]
/// No description
GPIO_QSPI_SCLK_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SCLK_EDGE_LOW [2:2]
/// No description
GPIO_QSPI_SCLK_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SCLK_EDGE_HIGH [3:3]
/// No description
GPIO_QSPI_SCLK_EDGE_HIGH: u1 = 0,
/// GPIO_QSPI_SS_LEVEL_LOW [4:4]
/// No description
GPIO_QSPI_SS_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SS_LEVEL_HIGH [5:5]
/// No description
GPIO_QSPI_SS_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SS_EDGE_LOW [6:6]
/// No description
GPIO_QSPI_SS_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SS_EDGE_HIGH [7:7]
/// No description
GPIO_QSPI_SS_EDGE_HIGH: u1 = 0,
/// GPIO_QSPI_SD0_LEVEL_LOW [8:8]
/// No description
GPIO_QSPI_SD0_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SD0_LEVEL_HIGH [9:9]
/// No description
GPIO_QSPI_SD0_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SD0_EDGE_LOW [10:10]
/// No description
GPIO_QSPI_SD0_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SD0_EDGE_HIGH [11:11]
/// No description
GPIO_QSPI_SD0_EDGE_HIGH: u1 = 0,
/// GPIO_QSPI_SD1_LEVEL_LOW [12:12]
/// No description
GPIO_QSPI_SD1_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SD1_LEVEL_HIGH [13:13]
/// No description
GPIO_QSPI_SD1_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SD1_EDGE_LOW [14:14]
/// No description
GPIO_QSPI_SD1_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SD1_EDGE_HIGH [15:15]
/// No description
GPIO_QSPI_SD1_EDGE_HIGH: u1 = 0,
/// GPIO_QSPI_SD2_LEVEL_LOW [16:16]
/// No description
GPIO_QSPI_SD2_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SD2_LEVEL_HIGH [17:17]
/// No description
GPIO_QSPI_SD2_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SD2_EDGE_LOW [18:18]
/// No description
GPIO_QSPI_SD2_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SD2_EDGE_HIGH [19:19]
/// No description
GPIO_QSPI_SD2_EDGE_HIGH: u1 = 0,
/// GPIO_QSPI_SD3_LEVEL_LOW [20:20]
/// No description
GPIO_QSPI_SD3_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SD3_LEVEL_HIGH [21:21]
/// No description
GPIO_QSPI_SD3_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SD3_EDGE_LOW [22:22]
/// No description
GPIO_QSPI_SD3_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SD3_EDGE_HIGH [23:23]
/// No description
GPIO_QSPI_SD3_EDGE_HIGH: u1 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// Interrupt status after masking &amp; forcing for proc1
pub const PROC1_INTS = Register(PROC1_INTS_val).init(base_address + 0x48);

/// PROC1_INTF
const PROC1_INTF_val = packed struct {
/// GPIO_QSPI_SCLK_LEVEL_LOW [0:0]
/// No description
GPIO_QSPI_SCLK_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SCLK_LEVEL_HIGH [1:1]
/// No description
GPIO_QSPI_SCLK_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SCLK_EDGE_LOW [2:2]
/// No description
GPIO_QSPI_SCLK_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SCLK_EDGE_HIGH [3:3]
/// No description
GPIO_QSPI_SCLK_EDGE_HIGH: u1 = 0,
/// GPIO_QSPI_SS_LEVEL_LOW [4:4]
/// No description
GPIO_QSPI_SS_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SS_LEVEL_HIGH [5:5]
/// No description
GPIO_QSPI_SS_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SS_EDGE_LOW [6:6]
/// No description
GPIO_QSPI_SS_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SS_EDGE_HIGH [7:7]
/// No description
GPIO_QSPI_SS_EDGE_HIGH: u1 = 0,
/// GPIO_QSPI_SD0_LEVEL_LOW [8:8]
/// No description
GPIO_QSPI_SD0_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SD0_LEVEL_HIGH [9:9]
/// No description
GPIO_QSPI_SD0_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SD0_EDGE_LOW [10:10]
/// No description
GPIO_QSPI_SD0_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SD0_EDGE_HIGH [11:11]
/// No description
GPIO_QSPI_SD0_EDGE_HIGH: u1 = 0,
/// GPIO_QSPI_SD1_LEVEL_LOW [12:12]
/// No description
GPIO_QSPI_SD1_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SD1_LEVEL_HIGH [13:13]
/// No description
GPIO_QSPI_SD1_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SD1_EDGE_LOW [14:14]
/// No description
GPIO_QSPI_SD1_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SD1_EDGE_HIGH [15:15]
/// No description
GPIO_QSPI_SD1_EDGE_HIGH: u1 = 0,
/// GPIO_QSPI_SD2_LEVEL_LOW [16:16]
/// No description
GPIO_QSPI_SD2_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SD2_LEVEL_HIGH [17:17]
/// No description
GPIO_QSPI_SD2_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SD2_EDGE_LOW [18:18]
/// No description
GPIO_QSPI_SD2_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SD2_EDGE_HIGH [19:19]
/// No description
GPIO_QSPI_SD2_EDGE_HIGH: u1 = 0,
/// GPIO_QSPI_SD3_LEVEL_LOW [20:20]
/// No description
GPIO_QSPI_SD3_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SD3_LEVEL_HIGH [21:21]
/// No description
GPIO_QSPI_SD3_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SD3_EDGE_LOW [22:22]
/// No description
GPIO_QSPI_SD3_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SD3_EDGE_HIGH [23:23]
/// No description
GPIO_QSPI_SD3_EDGE_HIGH: u1 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// Interrupt Force for proc1
pub const PROC1_INTF = Register(PROC1_INTF_val).init(base_address + 0x44);

/// PROC1_INTE
const PROC1_INTE_val = packed struct {
/// GPIO_QSPI_SCLK_LEVEL_LOW [0:0]
/// No description
GPIO_QSPI_SCLK_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SCLK_LEVEL_HIGH [1:1]
/// No description
GPIO_QSPI_SCLK_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SCLK_EDGE_LOW [2:2]
/// No description
GPIO_QSPI_SCLK_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SCLK_EDGE_HIGH [3:3]
/// No description
GPIO_QSPI_SCLK_EDGE_HIGH: u1 = 0,
/// GPIO_QSPI_SS_LEVEL_LOW [4:4]
/// No description
GPIO_QSPI_SS_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SS_LEVEL_HIGH [5:5]
/// No description
GPIO_QSPI_SS_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SS_EDGE_LOW [6:6]
/// No description
GPIO_QSPI_SS_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SS_EDGE_HIGH [7:7]
/// No description
GPIO_QSPI_SS_EDGE_HIGH: u1 = 0,
/// GPIO_QSPI_SD0_LEVEL_LOW [8:8]
/// No description
GPIO_QSPI_SD0_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SD0_LEVEL_HIGH [9:9]
/// No description
GPIO_QSPI_SD0_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SD0_EDGE_LOW [10:10]
/// No description
GPIO_QSPI_SD0_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SD0_EDGE_HIGH [11:11]
/// No description
GPIO_QSPI_SD0_EDGE_HIGH: u1 = 0,
/// GPIO_QSPI_SD1_LEVEL_LOW [12:12]
/// No description
GPIO_QSPI_SD1_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SD1_LEVEL_HIGH [13:13]
/// No description
GPIO_QSPI_SD1_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SD1_EDGE_LOW [14:14]
/// No description
GPIO_QSPI_SD1_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SD1_EDGE_HIGH [15:15]
/// No description
GPIO_QSPI_SD1_EDGE_HIGH: u1 = 0,
/// GPIO_QSPI_SD2_LEVEL_LOW [16:16]
/// No description
GPIO_QSPI_SD2_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SD2_LEVEL_HIGH [17:17]
/// No description
GPIO_QSPI_SD2_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SD2_EDGE_LOW [18:18]
/// No description
GPIO_QSPI_SD2_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SD2_EDGE_HIGH [19:19]
/// No description
GPIO_QSPI_SD2_EDGE_HIGH: u1 = 0,
/// GPIO_QSPI_SD3_LEVEL_LOW [20:20]
/// No description
GPIO_QSPI_SD3_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SD3_LEVEL_HIGH [21:21]
/// No description
GPIO_QSPI_SD3_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SD3_EDGE_LOW [22:22]
/// No description
GPIO_QSPI_SD3_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SD3_EDGE_HIGH [23:23]
/// No description
GPIO_QSPI_SD3_EDGE_HIGH: u1 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// Interrupt Enable for proc1
pub const PROC1_INTE = Register(PROC1_INTE_val).init(base_address + 0x40);

/// PROC0_INTS
const PROC0_INTS_val = packed struct {
/// GPIO_QSPI_SCLK_LEVEL_LOW [0:0]
/// No description
GPIO_QSPI_SCLK_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SCLK_LEVEL_HIGH [1:1]
/// No description
GPIO_QSPI_SCLK_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SCLK_EDGE_LOW [2:2]
/// No description
GPIO_QSPI_SCLK_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SCLK_EDGE_HIGH [3:3]
/// No description
GPIO_QSPI_SCLK_EDGE_HIGH: u1 = 0,
/// GPIO_QSPI_SS_LEVEL_LOW [4:4]
/// No description
GPIO_QSPI_SS_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SS_LEVEL_HIGH [5:5]
/// No description
GPIO_QSPI_SS_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SS_EDGE_LOW [6:6]
/// No description
GPIO_QSPI_SS_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SS_EDGE_HIGH [7:7]
/// No description
GPIO_QSPI_SS_EDGE_HIGH: u1 = 0,
/// GPIO_QSPI_SD0_LEVEL_LOW [8:8]
/// No description
GPIO_QSPI_SD0_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SD0_LEVEL_HIGH [9:9]
/// No description
GPIO_QSPI_SD0_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SD0_EDGE_LOW [10:10]
/// No description
GPIO_QSPI_SD0_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SD0_EDGE_HIGH [11:11]
/// No description
GPIO_QSPI_SD0_EDGE_HIGH: u1 = 0,
/// GPIO_QSPI_SD1_LEVEL_LOW [12:12]
/// No description
GPIO_QSPI_SD1_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SD1_LEVEL_HIGH [13:13]
/// No description
GPIO_QSPI_SD1_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SD1_EDGE_LOW [14:14]
/// No description
GPIO_QSPI_SD1_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SD1_EDGE_HIGH [15:15]
/// No description
GPIO_QSPI_SD1_EDGE_HIGH: u1 = 0,
/// GPIO_QSPI_SD2_LEVEL_LOW [16:16]
/// No description
GPIO_QSPI_SD2_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SD2_LEVEL_HIGH [17:17]
/// No description
GPIO_QSPI_SD2_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SD2_EDGE_LOW [18:18]
/// No description
GPIO_QSPI_SD2_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SD2_EDGE_HIGH [19:19]
/// No description
GPIO_QSPI_SD2_EDGE_HIGH: u1 = 0,
/// GPIO_QSPI_SD3_LEVEL_LOW [20:20]
/// No description
GPIO_QSPI_SD3_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SD3_LEVEL_HIGH [21:21]
/// No description
GPIO_QSPI_SD3_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SD3_EDGE_LOW [22:22]
/// No description
GPIO_QSPI_SD3_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SD3_EDGE_HIGH [23:23]
/// No description
GPIO_QSPI_SD3_EDGE_HIGH: u1 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// Interrupt status after masking &amp; forcing for proc0
pub const PROC0_INTS = Register(PROC0_INTS_val).init(base_address + 0x3c);

/// PROC0_INTF
const PROC0_INTF_val = packed struct {
/// GPIO_QSPI_SCLK_LEVEL_LOW [0:0]
/// No description
GPIO_QSPI_SCLK_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SCLK_LEVEL_HIGH [1:1]
/// No description
GPIO_QSPI_SCLK_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SCLK_EDGE_LOW [2:2]
/// No description
GPIO_QSPI_SCLK_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SCLK_EDGE_HIGH [3:3]
/// No description
GPIO_QSPI_SCLK_EDGE_HIGH: u1 = 0,
/// GPIO_QSPI_SS_LEVEL_LOW [4:4]
/// No description
GPIO_QSPI_SS_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SS_LEVEL_HIGH [5:5]
/// No description
GPIO_QSPI_SS_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SS_EDGE_LOW [6:6]
/// No description
GPIO_QSPI_SS_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SS_EDGE_HIGH [7:7]
/// No description
GPIO_QSPI_SS_EDGE_HIGH: u1 = 0,
/// GPIO_QSPI_SD0_LEVEL_LOW [8:8]
/// No description
GPIO_QSPI_SD0_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SD0_LEVEL_HIGH [9:9]
/// No description
GPIO_QSPI_SD0_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SD0_EDGE_LOW [10:10]
/// No description
GPIO_QSPI_SD0_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SD0_EDGE_HIGH [11:11]
/// No description
GPIO_QSPI_SD0_EDGE_HIGH: u1 = 0,
/// GPIO_QSPI_SD1_LEVEL_LOW [12:12]
/// No description
GPIO_QSPI_SD1_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SD1_LEVEL_HIGH [13:13]
/// No description
GPIO_QSPI_SD1_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SD1_EDGE_LOW [14:14]
/// No description
GPIO_QSPI_SD1_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SD1_EDGE_HIGH [15:15]
/// No description
GPIO_QSPI_SD1_EDGE_HIGH: u1 = 0,
/// GPIO_QSPI_SD2_LEVEL_LOW [16:16]
/// No description
GPIO_QSPI_SD2_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SD2_LEVEL_HIGH [17:17]
/// No description
GPIO_QSPI_SD2_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SD2_EDGE_LOW [18:18]
/// No description
GPIO_QSPI_SD2_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SD2_EDGE_HIGH [19:19]
/// No description
GPIO_QSPI_SD2_EDGE_HIGH: u1 = 0,
/// GPIO_QSPI_SD3_LEVEL_LOW [20:20]
/// No description
GPIO_QSPI_SD3_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SD3_LEVEL_HIGH [21:21]
/// No description
GPIO_QSPI_SD3_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SD3_EDGE_LOW [22:22]
/// No description
GPIO_QSPI_SD3_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SD3_EDGE_HIGH [23:23]
/// No description
GPIO_QSPI_SD3_EDGE_HIGH: u1 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// Interrupt Force for proc0
pub const PROC0_INTF = Register(PROC0_INTF_val).init(base_address + 0x38);

/// PROC0_INTE
const PROC0_INTE_val = packed struct {
/// GPIO_QSPI_SCLK_LEVEL_LOW [0:0]
/// No description
GPIO_QSPI_SCLK_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SCLK_LEVEL_HIGH [1:1]
/// No description
GPIO_QSPI_SCLK_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SCLK_EDGE_LOW [2:2]
/// No description
GPIO_QSPI_SCLK_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SCLK_EDGE_HIGH [3:3]
/// No description
GPIO_QSPI_SCLK_EDGE_HIGH: u1 = 0,
/// GPIO_QSPI_SS_LEVEL_LOW [4:4]
/// No description
GPIO_QSPI_SS_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SS_LEVEL_HIGH [5:5]
/// No description
GPIO_QSPI_SS_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SS_EDGE_LOW [6:6]
/// No description
GPIO_QSPI_SS_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SS_EDGE_HIGH [7:7]
/// No description
GPIO_QSPI_SS_EDGE_HIGH: u1 = 0,
/// GPIO_QSPI_SD0_LEVEL_LOW [8:8]
/// No description
GPIO_QSPI_SD0_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SD0_LEVEL_HIGH [9:9]
/// No description
GPIO_QSPI_SD0_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SD0_EDGE_LOW [10:10]
/// No description
GPIO_QSPI_SD0_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SD0_EDGE_HIGH [11:11]
/// No description
GPIO_QSPI_SD0_EDGE_HIGH: u1 = 0,
/// GPIO_QSPI_SD1_LEVEL_LOW [12:12]
/// No description
GPIO_QSPI_SD1_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SD1_LEVEL_HIGH [13:13]
/// No description
GPIO_QSPI_SD1_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SD1_EDGE_LOW [14:14]
/// No description
GPIO_QSPI_SD1_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SD1_EDGE_HIGH [15:15]
/// No description
GPIO_QSPI_SD1_EDGE_HIGH: u1 = 0,
/// GPIO_QSPI_SD2_LEVEL_LOW [16:16]
/// No description
GPIO_QSPI_SD2_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SD2_LEVEL_HIGH [17:17]
/// No description
GPIO_QSPI_SD2_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SD2_EDGE_LOW [18:18]
/// No description
GPIO_QSPI_SD2_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SD2_EDGE_HIGH [19:19]
/// No description
GPIO_QSPI_SD2_EDGE_HIGH: u1 = 0,
/// GPIO_QSPI_SD3_LEVEL_LOW [20:20]
/// No description
GPIO_QSPI_SD3_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SD3_LEVEL_HIGH [21:21]
/// No description
GPIO_QSPI_SD3_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SD3_EDGE_LOW [22:22]
/// No description
GPIO_QSPI_SD3_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SD3_EDGE_HIGH [23:23]
/// No description
GPIO_QSPI_SD3_EDGE_HIGH: u1 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// Interrupt Enable for proc0
pub const PROC0_INTE = Register(PROC0_INTE_val).init(base_address + 0x34);

/// INTR
const INTR_val = packed struct {
/// GPIO_QSPI_SCLK_LEVEL_LOW [0:0]
/// No description
GPIO_QSPI_SCLK_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SCLK_LEVEL_HIGH [1:1]
/// No description
GPIO_QSPI_SCLK_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SCLK_EDGE_LOW [2:2]
/// No description
GPIO_QSPI_SCLK_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SCLK_EDGE_HIGH [3:3]
/// No description
GPIO_QSPI_SCLK_EDGE_HIGH: u1 = 0,
/// GPIO_QSPI_SS_LEVEL_LOW [4:4]
/// No description
GPIO_QSPI_SS_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SS_LEVEL_HIGH [5:5]
/// No description
GPIO_QSPI_SS_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SS_EDGE_LOW [6:6]
/// No description
GPIO_QSPI_SS_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SS_EDGE_HIGH [7:7]
/// No description
GPIO_QSPI_SS_EDGE_HIGH: u1 = 0,
/// GPIO_QSPI_SD0_LEVEL_LOW [8:8]
/// No description
GPIO_QSPI_SD0_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SD0_LEVEL_HIGH [9:9]
/// No description
GPIO_QSPI_SD0_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SD0_EDGE_LOW [10:10]
/// No description
GPIO_QSPI_SD0_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SD0_EDGE_HIGH [11:11]
/// No description
GPIO_QSPI_SD0_EDGE_HIGH: u1 = 0,
/// GPIO_QSPI_SD1_LEVEL_LOW [12:12]
/// No description
GPIO_QSPI_SD1_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SD1_LEVEL_HIGH [13:13]
/// No description
GPIO_QSPI_SD1_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SD1_EDGE_LOW [14:14]
/// No description
GPIO_QSPI_SD1_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SD1_EDGE_HIGH [15:15]
/// No description
GPIO_QSPI_SD1_EDGE_HIGH: u1 = 0,
/// GPIO_QSPI_SD2_LEVEL_LOW [16:16]
/// No description
GPIO_QSPI_SD2_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SD2_LEVEL_HIGH [17:17]
/// No description
GPIO_QSPI_SD2_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SD2_EDGE_LOW [18:18]
/// No description
GPIO_QSPI_SD2_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SD2_EDGE_HIGH [19:19]
/// No description
GPIO_QSPI_SD2_EDGE_HIGH: u1 = 0,
/// GPIO_QSPI_SD3_LEVEL_LOW [20:20]
/// No description
GPIO_QSPI_SD3_LEVEL_LOW: u1 = 0,
/// GPIO_QSPI_SD3_LEVEL_HIGH [21:21]
/// No description
GPIO_QSPI_SD3_LEVEL_HIGH: u1 = 0,
/// GPIO_QSPI_SD3_EDGE_LOW [22:22]
/// No description
GPIO_QSPI_SD3_EDGE_LOW: u1 = 0,
/// GPIO_QSPI_SD3_EDGE_HIGH [23:23]
/// No description
GPIO_QSPI_SD3_EDGE_HIGH: u1 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// Raw Interrupts
pub const INTR = Register(INTR_val).init(base_address + 0x30);

/// GPIO_QSPI_SD3_CTRL
const GPIO_QSPI_SD3_CTRL_val = packed struct {
/// FUNCSEL [0:4]
/// 0-31 -&gt; selects pin function according to the gpio table\n
FUNCSEL: u5 = 31,
/// unused [5:7]
_unused5: u3 = 0,
/// OUTOVER [8:9]
/// No description
OUTOVER: u2 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEOVER [12:13]
/// No description
OEOVER: u2 = 0,
/// unused [14:15]
_unused14: u2 = 0,
/// INOVER [16:17]
/// No description
INOVER: u2 = 0,
/// unused [18:27]
_unused18: u6 = 0,
_unused24: u4 = 0,
/// IRQOVER [28:29]
/// No description
IRQOVER: u2 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// GPIO control including function select and overrides.
pub const GPIO_QSPI_SD3_CTRL = Register(GPIO_QSPI_SD3_CTRL_val).init(base_address + 0x2c);

/// GPIO_QSPI_SD3_STATUS
const GPIO_QSPI_SD3_STATUS_val = packed struct {
/// unused [0:7]
_unused0: u8 = 0,
/// OUTFROMPERI [8:8]
/// output signal from selected peripheral, before register override is applied
OUTFROMPERI: u1 = 0,
/// OUTTOPAD [9:9]
/// output signal to pad after register override is applied
OUTTOPAD: u1 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEFROMPERI [12:12]
/// output enable from selected peripheral, before register override is applied
OEFROMPERI: u1 = 0,
/// OETOPAD [13:13]
/// output enable to pad after register override is applied
OETOPAD: u1 = 0,
/// unused [14:16]
_unused14: u2 = 0,
_unused16: u1 = 0,
/// INFROMPAD [17:17]
/// input signal from pad, before override is applied
INFROMPAD: u1 = 0,
/// unused [18:18]
_unused18: u1 = 0,
/// INTOPERI [19:19]
/// input signal to peripheral, after override is applied
INTOPERI: u1 = 0,
/// unused [20:23]
_unused20: u4 = 0,
/// IRQFROMPAD [24:24]
/// interrupt from pad before override is applied
IRQFROMPAD: u1 = 0,
/// unused [25:25]
_unused25: u1 = 0,
/// IRQTOPROC [26:26]
/// interrupt to processors, after override is applied
IRQTOPROC: u1 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// GPIO status
pub const GPIO_QSPI_SD3_STATUS = Register(GPIO_QSPI_SD3_STATUS_val).init(base_address + 0x28);

/// GPIO_QSPI_SD2_CTRL
const GPIO_QSPI_SD2_CTRL_val = packed struct {
/// FUNCSEL [0:4]
/// 0-31 -&gt; selects pin function according to the gpio table\n
FUNCSEL: u5 = 31,
/// unused [5:7]
_unused5: u3 = 0,
/// OUTOVER [8:9]
/// No description
OUTOVER: u2 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEOVER [12:13]
/// No description
OEOVER: u2 = 0,
/// unused [14:15]
_unused14: u2 = 0,
/// INOVER [16:17]
/// No description
INOVER: u2 = 0,
/// unused [18:27]
_unused18: u6 = 0,
_unused24: u4 = 0,
/// IRQOVER [28:29]
/// No description
IRQOVER: u2 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// GPIO control including function select and overrides.
pub const GPIO_QSPI_SD2_CTRL = Register(GPIO_QSPI_SD2_CTRL_val).init(base_address + 0x24);

/// GPIO_QSPI_SD2_STATUS
const GPIO_QSPI_SD2_STATUS_val = packed struct {
/// unused [0:7]
_unused0: u8 = 0,
/// OUTFROMPERI [8:8]
/// output signal from selected peripheral, before register override is applied
OUTFROMPERI: u1 = 0,
/// OUTTOPAD [9:9]
/// output signal to pad after register override is applied
OUTTOPAD: u1 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEFROMPERI [12:12]
/// output enable from selected peripheral, before register override is applied
OEFROMPERI: u1 = 0,
/// OETOPAD [13:13]
/// output enable to pad after register override is applied
OETOPAD: u1 = 0,
/// unused [14:16]
_unused14: u2 = 0,
_unused16: u1 = 0,
/// INFROMPAD [17:17]
/// input signal from pad, before override is applied
INFROMPAD: u1 = 0,
/// unused [18:18]
_unused18: u1 = 0,
/// INTOPERI [19:19]
/// input signal to peripheral, after override is applied
INTOPERI: u1 = 0,
/// unused [20:23]
_unused20: u4 = 0,
/// IRQFROMPAD [24:24]
/// interrupt from pad before override is applied
IRQFROMPAD: u1 = 0,
/// unused [25:25]
_unused25: u1 = 0,
/// IRQTOPROC [26:26]
/// interrupt to processors, after override is applied
IRQTOPROC: u1 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// GPIO status
pub const GPIO_QSPI_SD2_STATUS = Register(GPIO_QSPI_SD2_STATUS_val).init(base_address + 0x20);

/// GPIO_QSPI_SD1_CTRL
const GPIO_QSPI_SD1_CTRL_val = packed struct {
/// FUNCSEL [0:4]
/// 0-31 -&gt; selects pin function according to the gpio table\n
FUNCSEL: u5 = 31,
/// unused [5:7]
_unused5: u3 = 0,
/// OUTOVER [8:9]
/// No description
OUTOVER: u2 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEOVER [12:13]
/// No description
OEOVER: u2 = 0,
/// unused [14:15]
_unused14: u2 = 0,
/// INOVER [16:17]
/// No description
INOVER: u2 = 0,
/// unused [18:27]
_unused18: u6 = 0,
_unused24: u4 = 0,
/// IRQOVER [28:29]
/// No description
IRQOVER: u2 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// GPIO control including function select and overrides.
pub const GPIO_QSPI_SD1_CTRL = Register(GPIO_QSPI_SD1_CTRL_val).init(base_address + 0x1c);

/// GPIO_QSPI_SD1_STATUS
const GPIO_QSPI_SD1_STATUS_val = packed struct {
/// unused [0:7]
_unused0: u8 = 0,
/// OUTFROMPERI [8:8]
/// output signal from selected peripheral, before register override is applied
OUTFROMPERI: u1 = 0,
/// OUTTOPAD [9:9]
/// output signal to pad after register override is applied
OUTTOPAD: u1 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEFROMPERI [12:12]
/// output enable from selected peripheral, before register override is applied
OEFROMPERI: u1 = 0,
/// OETOPAD [13:13]
/// output enable to pad after register override is applied
OETOPAD: u1 = 0,
/// unused [14:16]
_unused14: u2 = 0,
_unused16: u1 = 0,
/// INFROMPAD [17:17]
/// input signal from pad, before override is applied
INFROMPAD: u1 = 0,
/// unused [18:18]
_unused18: u1 = 0,
/// INTOPERI [19:19]
/// input signal to peripheral, after override is applied
INTOPERI: u1 = 0,
/// unused [20:23]
_unused20: u4 = 0,
/// IRQFROMPAD [24:24]
/// interrupt from pad before override is applied
IRQFROMPAD: u1 = 0,
/// unused [25:25]
_unused25: u1 = 0,
/// IRQTOPROC [26:26]
/// interrupt to processors, after override is applied
IRQTOPROC: u1 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// GPIO status
pub const GPIO_QSPI_SD1_STATUS = Register(GPIO_QSPI_SD1_STATUS_val).init(base_address + 0x18);

/// GPIO_QSPI_SD0_CTRL
const GPIO_QSPI_SD0_CTRL_val = packed struct {
/// FUNCSEL [0:4]
/// 0-31 -&gt; selects pin function according to the gpio table\n
FUNCSEL: u5 = 31,
/// unused [5:7]
_unused5: u3 = 0,
/// OUTOVER [8:9]
/// No description
OUTOVER: u2 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEOVER [12:13]
/// No description
OEOVER: u2 = 0,
/// unused [14:15]
_unused14: u2 = 0,
/// INOVER [16:17]
/// No description
INOVER: u2 = 0,
/// unused [18:27]
_unused18: u6 = 0,
_unused24: u4 = 0,
/// IRQOVER [28:29]
/// No description
IRQOVER: u2 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// GPIO control including function select and overrides.
pub const GPIO_QSPI_SD0_CTRL = Register(GPIO_QSPI_SD0_CTRL_val).init(base_address + 0x14);

/// GPIO_QSPI_SD0_STATUS
const GPIO_QSPI_SD0_STATUS_val = packed struct {
/// unused [0:7]
_unused0: u8 = 0,
/// OUTFROMPERI [8:8]
/// output signal from selected peripheral, before register override is applied
OUTFROMPERI: u1 = 0,
/// OUTTOPAD [9:9]
/// output signal to pad after register override is applied
OUTTOPAD: u1 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEFROMPERI [12:12]
/// output enable from selected peripheral, before register override is applied
OEFROMPERI: u1 = 0,
/// OETOPAD [13:13]
/// output enable to pad after register override is applied
OETOPAD: u1 = 0,
/// unused [14:16]
_unused14: u2 = 0,
_unused16: u1 = 0,
/// INFROMPAD [17:17]
/// input signal from pad, before override is applied
INFROMPAD: u1 = 0,
/// unused [18:18]
_unused18: u1 = 0,
/// INTOPERI [19:19]
/// input signal to peripheral, after override is applied
INTOPERI: u1 = 0,
/// unused [20:23]
_unused20: u4 = 0,
/// IRQFROMPAD [24:24]
/// interrupt from pad before override is applied
IRQFROMPAD: u1 = 0,
/// unused [25:25]
_unused25: u1 = 0,
/// IRQTOPROC [26:26]
/// interrupt to processors, after override is applied
IRQTOPROC: u1 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// GPIO status
pub const GPIO_QSPI_SD0_STATUS = Register(GPIO_QSPI_SD0_STATUS_val).init(base_address + 0x10);

/// GPIO_QSPI_SS_CTRL
const GPIO_QSPI_SS_CTRL_val = packed struct {
/// FUNCSEL [0:4]
/// 0-31 -&gt; selects pin function according to the gpio table\n
FUNCSEL: u5 = 31,
/// unused [5:7]
_unused5: u3 = 0,
/// OUTOVER [8:9]
/// No description
OUTOVER: u2 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEOVER [12:13]
/// No description
OEOVER: u2 = 0,
/// unused [14:15]
_unused14: u2 = 0,
/// INOVER [16:17]
/// No description
INOVER: u2 = 0,
/// unused [18:27]
_unused18: u6 = 0,
_unused24: u4 = 0,
/// IRQOVER [28:29]
/// No description
IRQOVER: u2 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// GPIO control including function select and overrides.
pub const GPIO_QSPI_SS_CTRL = Register(GPIO_QSPI_SS_CTRL_val).init(base_address + 0xc);

/// GPIO_QSPI_SS_STATUS
const GPIO_QSPI_SS_STATUS_val = packed struct {
/// unused [0:7]
_unused0: u8 = 0,
/// OUTFROMPERI [8:8]
/// output signal from selected peripheral, before register override is applied
OUTFROMPERI: u1 = 0,
/// OUTTOPAD [9:9]
/// output signal to pad after register override is applied
OUTTOPAD: u1 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEFROMPERI [12:12]
/// output enable from selected peripheral, before register override is applied
OEFROMPERI: u1 = 0,
/// OETOPAD [13:13]
/// output enable to pad after register override is applied
OETOPAD: u1 = 0,
/// unused [14:16]
_unused14: u2 = 0,
_unused16: u1 = 0,
/// INFROMPAD [17:17]
/// input signal from pad, before override is applied
INFROMPAD: u1 = 0,
/// unused [18:18]
_unused18: u1 = 0,
/// INTOPERI [19:19]
/// input signal to peripheral, after override is applied
INTOPERI: u1 = 0,
/// unused [20:23]
_unused20: u4 = 0,
/// IRQFROMPAD [24:24]
/// interrupt from pad before override is applied
IRQFROMPAD: u1 = 0,
/// unused [25:25]
_unused25: u1 = 0,
/// IRQTOPROC [26:26]
/// interrupt to processors, after override is applied
IRQTOPROC: u1 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// GPIO status
pub const GPIO_QSPI_SS_STATUS = Register(GPIO_QSPI_SS_STATUS_val).init(base_address + 0x8);

/// GPIO_QSPI_SCLK_CTRL
const GPIO_QSPI_SCLK_CTRL_val = packed struct {
/// FUNCSEL [0:4]
/// 0-31 -&gt; selects pin function according to the gpio table\n
FUNCSEL: u5 = 31,
/// unused [5:7]
_unused5: u3 = 0,
/// OUTOVER [8:9]
/// No description
OUTOVER: u2 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEOVER [12:13]
/// No description
OEOVER: u2 = 0,
/// unused [14:15]
_unused14: u2 = 0,
/// INOVER [16:17]
/// No description
INOVER: u2 = 0,
/// unused [18:27]
_unused18: u6 = 0,
_unused24: u4 = 0,
/// IRQOVER [28:29]
/// No description
IRQOVER: u2 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// GPIO control including function select and overrides.
pub const GPIO_QSPI_SCLK_CTRL = Register(GPIO_QSPI_SCLK_CTRL_val).init(base_address + 0x4);

/// GPIO_QSPI_SCLK_STATUS
const GPIO_QSPI_SCLK_STATUS_val = packed struct {
/// unused [0:7]
_unused0: u8 = 0,
/// OUTFROMPERI [8:8]
/// output signal from selected peripheral, before register override is applied
OUTFROMPERI: u1 = 0,
/// OUTTOPAD [9:9]
/// output signal to pad after register override is applied
OUTTOPAD: u1 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// OEFROMPERI [12:12]
/// output enable from selected peripheral, before register override is applied
OEFROMPERI: u1 = 0,
/// OETOPAD [13:13]
/// output enable to pad after register override is applied
OETOPAD: u1 = 0,
/// unused [14:16]
_unused14: u2 = 0,
_unused16: u1 = 0,
/// INFROMPAD [17:17]
/// input signal from pad, before override is applied
INFROMPAD: u1 = 0,
/// unused [18:18]
_unused18: u1 = 0,
/// INTOPERI [19:19]
/// input signal to peripheral, after override is applied
INTOPERI: u1 = 0,
/// unused [20:23]
_unused20: u4 = 0,
/// IRQFROMPAD [24:24]
/// interrupt from pad before override is applied
IRQFROMPAD: u1 = 0,
/// unused [25:25]
_unused25: u1 = 0,
/// IRQTOPROC [26:26]
/// interrupt to processors, after override is applied
IRQTOPROC: u1 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// GPIO status
pub const GPIO_QSPI_SCLK_STATUS = Register(GPIO_QSPI_SCLK_STATUS_val).init(base_address + 0x0);
};

/// No description
pub const PADS_BANK0 = struct {

const base_address = 0x4001c000;
/// SWD
const SWD_val = packed struct {
/// SLEWFAST [0:0]
/// Slew rate control. 1 = Fast, 0 = Slow
SLEWFAST: u1 = 0,
/// SCHMITT [1:1]
/// Enable schmitt trigger
SCHMITT: u1 = 1,
/// PDE [2:2]
/// Pull down enable
PDE: u1 = 0,
/// PUE [3:3]
/// Pull up enable
PUE: u1 = 1,
/// DRIVE [4:5]
/// Drive strength.
DRIVE: u2 = 1,
/// IE [6:6]
/// Input enable
IE: u1 = 1,
/// OD [7:7]
/// Output disable. Has priority over output enable from peripherals
OD: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Pad control register
pub const SWD = Register(SWD_val).init(base_address + 0x80);

/// SWCLK
const SWCLK_val = packed struct {
/// SLEWFAST [0:0]
/// Slew rate control. 1 = Fast, 0 = Slow
SLEWFAST: u1 = 0,
/// SCHMITT [1:1]
/// Enable schmitt trigger
SCHMITT: u1 = 1,
/// PDE [2:2]
/// Pull down enable
PDE: u1 = 0,
/// PUE [3:3]
/// Pull up enable
PUE: u1 = 1,
/// DRIVE [4:5]
/// Drive strength.
DRIVE: u2 = 1,
/// IE [6:6]
/// Input enable
IE: u1 = 1,
/// OD [7:7]
/// Output disable. Has priority over output enable from peripherals
OD: u1 = 1,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Pad control register
pub const SWCLK = Register(SWCLK_val).init(base_address + 0x7c);

/// GPIO29
const GPIO29_val = packed struct {
/// SLEWFAST [0:0]
/// Slew rate control. 1 = Fast, 0 = Slow
SLEWFAST: u1 = 0,
/// SCHMITT [1:1]
/// Enable schmitt trigger
SCHMITT: u1 = 1,
/// PDE [2:2]
/// Pull down enable
PDE: u1 = 1,
/// PUE [3:3]
/// Pull up enable
PUE: u1 = 0,
/// DRIVE [4:5]
/// Drive strength.
DRIVE: u2 = 1,
/// IE [6:6]
/// Input enable
IE: u1 = 1,
/// OD [7:7]
/// Output disable. Has priority over output enable from peripherals
OD: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Pad control register
pub const GPIO29 = Register(GPIO29_val).init(base_address + 0x78);

/// GPIO28
const GPIO28_val = packed struct {
/// SLEWFAST [0:0]
/// Slew rate control. 1 = Fast, 0 = Slow
SLEWFAST: u1 = 0,
/// SCHMITT [1:1]
/// Enable schmitt trigger
SCHMITT: u1 = 1,
/// PDE [2:2]
/// Pull down enable
PDE: u1 = 1,
/// PUE [3:3]
/// Pull up enable
PUE: u1 = 0,
/// DRIVE [4:5]
/// Drive strength.
DRIVE: u2 = 1,
/// IE [6:6]
/// Input enable
IE: u1 = 1,
/// OD [7:7]
/// Output disable. Has priority over output enable from peripherals
OD: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Pad control register
pub const GPIO28 = Register(GPIO28_val).init(base_address + 0x74);

/// GPIO27
const GPIO27_val = packed struct {
/// SLEWFAST [0:0]
/// Slew rate control. 1 = Fast, 0 = Slow
SLEWFAST: u1 = 0,
/// SCHMITT [1:1]
/// Enable schmitt trigger
SCHMITT: u1 = 1,
/// PDE [2:2]
/// Pull down enable
PDE: u1 = 1,
/// PUE [3:3]
/// Pull up enable
PUE: u1 = 0,
/// DRIVE [4:5]
/// Drive strength.
DRIVE: u2 = 1,
/// IE [6:6]
/// Input enable
IE: u1 = 1,
/// OD [7:7]
/// Output disable. Has priority over output enable from peripherals
OD: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Pad control register
pub const GPIO27 = Register(GPIO27_val).init(base_address + 0x70);

/// GPIO26
const GPIO26_val = packed struct {
/// SLEWFAST [0:0]
/// Slew rate control. 1 = Fast, 0 = Slow
SLEWFAST: u1 = 0,
/// SCHMITT [1:1]
/// Enable schmitt trigger
SCHMITT: u1 = 1,
/// PDE [2:2]
/// Pull down enable
PDE: u1 = 1,
/// PUE [3:3]
/// Pull up enable
PUE: u1 = 0,
/// DRIVE [4:5]
/// Drive strength.
DRIVE: u2 = 1,
/// IE [6:6]
/// Input enable
IE: u1 = 1,
/// OD [7:7]
/// Output disable. Has priority over output enable from peripherals
OD: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Pad control register
pub const GPIO26 = Register(GPIO26_val).init(base_address + 0x6c);

/// GPIO25
const GPIO25_val = packed struct {
/// SLEWFAST [0:0]
/// Slew rate control. 1 = Fast, 0 = Slow
SLEWFAST: u1 = 0,
/// SCHMITT [1:1]
/// Enable schmitt trigger
SCHMITT: u1 = 1,
/// PDE [2:2]
/// Pull down enable
PDE: u1 = 1,
/// PUE [3:3]
/// Pull up enable
PUE: u1 = 0,
/// DRIVE [4:5]
/// Drive strength.
DRIVE: u2 = 1,
/// IE [6:6]
/// Input enable
IE: u1 = 1,
/// OD [7:7]
/// Output disable. Has priority over output enable from peripherals
OD: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Pad control register
pub const GPIO25 = Register(GPIO25_val).init(base_address + 0x68);

/// GPIO24
const GPIO24_val = packed struct {
/// SLEWFAST [0:0]
/// Slew rate control. 1 = Fast, 0 = Slow
SLEWFAST: u1 = 0,
/// SCHMITT [1:1]
/// Enable schmitt trigger
SCHMITT: u1 = 1,
/// PDE [2:2]
/// Pull down enable
PDE: u1 = 1,
/// PUE [3:3]
/// Pull up enable
PUE: u1 = 0,
/// DRIVE [4:5]
/// Drive strength.
DRIVE: u2 = 1,
/// IE [6:6]
/// Input enable
IE: u1 = 1,
/// OD [7:7]
/// Output disable. Has priority over output enable from peripherals
OD: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Pad control register
pub const GPIO24 = Register(GPIO24_val).init(base_address + 0x64);

/// GPIO23
const GPIO23_val = packed struct {
/// SLEWFAST [0:0]
/// Slew rate control. 1 = Fast, 0 = Slow
SLEWFAST: u1 = 0,
/// SCHMITT [1:1]
/// Enable schmitt trigger
SCHMITT: u1 = 1,
/// PDE [2:2]
/// Pull down enable
PDE: u1 = 1,
/// PUE [3:3]
/// Pull up enable
PUE: u1 = 0,
/// DRIVE [4:5]
/// Drive strength.
DRIVE: u2 = 1,
/// IE [6:6]
/// Input enable
IE: u1 = 1,
/// OD [7:7]
/// Output disable. Has priority over output enable from peripherals
OD: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Pad control register
pub const GPIO23 = Register(GPIO23_val).init(base_address + 0x60);

/// GPIO22
const GPIO22_val = packed struct {
/// SLEWFAST [0:0]
/// Slew rate control. 1 = Fast, 0 = Slow
SLEWFAST: u1 = 0,
/// SCHMITT [1:1]
/// Enable schmitt trigger
SCHMITT: u1 = 1,
/// PDE [2:2]
/// Pull down enable
PDE: u1 = 1,
/// PUE [3:3]
/// Pull up enable
PUE: u1 = 0,
/// DRIVE [4:5]
/// Drive strength.
DRIVE: u2 = 1,
/// IE [6:6]
/// Input enable
IE: u1 = 1,
/// OD [7:7]
/// Output disable. Has priority over output enable from peripherals
OD: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Pad control register
pub const GPIO22 = Register(GPIO22_val).init(base_address + 0x5c);

/// GPIO21
const GPIO21_val = packed struct {
/// SLEWFAST [0:0]
/// Slew rate control. 1 = Fast, 0 = Slow
SLEWFAST: u1 = 0,
/// SCHMITT [1:1]
/// Enable schmitt trigger
SCHMITT: u1 = 1,
/// PDE [2:2]
/// Pull down enable
PDE: u1 = 1,
/// PUE [3:3]
/// Pull up enable
PUE: u1 = 0,
/// DRIVE [4:5]
/// Drive strength.
DRIVE: u2 = 1,
/// IE [6:6]
/// Input enable
IE: u1 = 1,
/// OD [7:7]
/// Output disable. Has priority over output enable from peripherals
OD: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Pad control register
pub const GPIO21 = Register(GPIO21_val).init(base_address + 0x58);

/// GPIO20
const GPIO20_val = packed struct {
/// SLEWFAST [0:0]
/// Slew rate control. 1 = Fast, 0 = Slow
SLEWFAST: u1 = 0,
/// SCHMITT [1:1]
/// Enable schmitt trigger
SCHMITT: u1 = 1,
/// PDE [2:2]
/// Pull down enable
PDE: u1 = 1,
/// PUE [3:3]
/// Pull up enable
PUE: u1 = 0,
/// DRIVE [4:5]
/// Drive strength.
DRIVE: u2 = 1,
/// IE [6:6]
/// Input enable
IE: u1 = 1,
/// OD [7:7]
/// Output disable. Has priority over output enable from peripherals
OD: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Pad control register
pub const GPIO20 = Register(GPIO20_val).init(base_address + 0x54);

/// GPIO19
const GPIO19_val = packed struct {
/// SLEWFAST [0:0]
/// Slew rate control. 1 = Fast, 0 = Slow
SLEWFAST: u1 = 0,
/// SCHMITT [1:1]
/// Enable schmitt trigger
SCHMITT: u1 = 1,
/// PDE [2:2]
/// Pull down enable
PDE: u1 = 1,
/// PUE [3:3]
/// Pull up enable
PUE: u1 = 0,
/// DRIVE [4:5]
/// Drive strength.
DRIVE: u2 = 1,
/// IE [6:6]
/// Input enable
IE: u1 = 1,
/// OD [7:7]
/// Output disable. Has priority over output enable from peripherals
OD: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Pad control register
pub const GPIO19 = Register(GPIO19_val).init(base_address + 0x50);

/// GPIO18
const GPIO18_val = packed struct {
/// SLEWFAST [0:0]
/// Slew rate control. 1 = Fast, 0 = Slow
SLEWFAST: u1 = 0,
/// SCHMITT [1:1]
/// Enable schmitt trigger
SCHMITT: u1 = 1,
/// PDE [2:2]
/// Pull down enable
PDE: u1 = 1,
/// PUE [3:3]
/// Pull up enable
PUE: u1 = 0,
/// DRIVE [4:5]
/// Drive strength.
DRIVE: u2 = 1,
/// IE [6:6]
/// Input enable
IE: u1 = 1,
/// OD [7:7]
/// Output disable. Has priority over output enable from peripherals
OD: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Pad control register
pub const GPIO18 = Register(GPIO18_val).init(base_address + 0x4c);

/// GPIO17
const GPIO17_val = packed struct {
/// SLEWFAST [0:0]
/// Slew rate control. 1 = Fast, 0 = Slow
SLEWFAST: u1 = 0,
/// SCHMITT [1:1]
/// Enable schmitt trigger
SCHMITT: u1 = 1,
/// PDE [2:2]
/// Pull down enable
PDE: u1 = 1,
/// PUE [3:3]
/// Pull up enable
PUE: u1 = 0,
/// DRIVE [4:5]
/// Drive strength.
DRIVE: u2 = 1,
/// IE [6:6]
/// Input enable
IE: u1 = 1,
/// OD [7:7]
/// Output disable. Has priority over output enable from peripherals
OD: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Pad control register
pub const GPIO17 = Register(GPIO17_val).init(base_address + 0x48);

/// GPIO16
const GPIO16_val = packed struct {
/// SLEWFAST [0:0]
/// Slew rate control. 1 = Fast, 0 = Slow
SLEWFAST: u1 = 0,
/// SCHMITT [1:1]
/// Enable schmitt trigger
SCHMITT: u1 = 1,
/// PDE [2:2]
/// Pull down enable
PDE: u1 = 1,
/// PUE [3:3]
/// Pull up enable
PUE: u1 = 0,
/// DRIVE [4:5]
/// Drive strength.
DRIVE: u2 = 1,
/// IE [6:6]
/// Input enable
IE: u1 = 1,
/// OD [7:7]
/// Output disable. Has priority over output enable from peripherals
OD: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Pad control register
pub const GPIO16 = Register(GPIO16_val).init(base_address + 0x44);

/// GPIO15
const GPIO15_val = packed struct {
/// SLEWFAST [0:0]
/// Slew rate control. 1 = Fast, 0 = Slow
SLEWFAST: u1 = 0,
/// SCHMITT [1:1]
/// Enable schmitt trigger
SCHMITT: u1 = 1,
/// PDE [2:2]
/// Pull down enable
PDE: u1 = 1,
/// PUE [3:3]
/// Pull up enable
PUE: u1 = 0,
/// DRIVE [4:5]
/// Drive strength.
DRIVE: u2 = 1,
/// IE [6:6]
/// Input enable
IE: u1 = 1,
/// OD [7:7]
/// Output disable. Has priority over output enable from peripherals
OD: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Pad control register
pub const GPIO15 = Register(GPIO15_val).init(base_address + 0x40);

/// GPIO14
const GPIO14_val = packed struct {
/// SLEWFAST [0:0]
/// Slew rate control. 1 = Fast, 0 = Slow
SLEWFAST: u1 = 0,
/// SCHMITT [1:1]
/// Enable schmitt trigger
SCHMITT: u1 = 1,
/// PDE [2:2]
/// Pull down enable
PDE: u1 = 1,
/// PUE [3:3]
/// Pull up enable
PUE: u1 = 0,
/// DRIVE [4:5]
/// Drive strength.
DRIVE: u2 = 1,
/// IE [6:6]
/// Input enable
IE: u1 = 1,
/// OD [7:7]
/// Output disable. Has priority over output enable from peripherals
OD: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Pad control register
pub const GPIO14 = Register(GPIO14_val).init(base_address + 0x3c);

/// GPIO13
const GPIO13_val = packed struct {
/// SLEWFAST [0:0]
/// Slew rate control. 1 = Fast, 0 = Slow
SLEWFAST: u1 = 0,
/// SCHMITT [1:1]
/// Enable schmitt trigger
SCHMITT: u1 = 1,
/// PDE [2:2]
/// Pull down enable
PDE: u1 = 1,
/// PUE [3:3]
/// Pull up enable
PUE: u1 = 0,
/// DRIVE [4:5]
/// Drive strength.
DRIVE: u2 = 1,
/// IE [6:6]
/// Input enable
IE: u1 = 1,
/// OD [7:7]
/// Output disable. Has priority over output enable from peripherals
OD: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Pad control register
pub const GPIO13 = Register(GPIO13_val).init(base_address + 0x38);

/// GPIO12
const GPIO12_val = packed struct {
/// SLEWFAST [0:0]
/// Slew rate control. 1 = Fast, 0 = Slow
SLEWFAST: u1 = 0,
/// SCHMITT [1:1]
/// Enable schmitt trigger
SCHMITT: u1 = 1,
/// PDE [2:2]
/// Pull down enable
PDE: u1 = 1,
/// PUE [3:3]
/// Pull up enable
PUE: u1 = 0,
/// DRIVE [4:5]
/// Drive strength.
DRIVE: u2 = 1,
/// IE [6:6]
/// Input enable
IE: u1 = 1,
/// OD [7:7]
/// Output disable. Has priority over output enable from peripherals
OD: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Pad control register
pub const GPIO12 = Register(GPIO12_val).init(base_address + 0x34);

/// GPIO11
const GPIO11_val = packed struct {
/// SLEWFAST [0:0]
/// Slew rate control. 1 = Fast, 0 = Slow
SLEWFAST: u1 = 0,
/// SCHMITT [1:1]
/// Enable schmitt trigger
SCHMITT: u1 = 1,
/// PDE [2:2]
/// Pull down enable
PDE: u1 = 1,
/// PUE [3:3]
/// Pull up enable
PUE: u1 = 0,
/// DRIVE [4:5]
/// Drive strength.
DRIVE: u2 = 1,
/// IE [6:6]
/// Input enable
IE: u1 = 1,
/// OD [7:7]
/// Output disable. Has priority over output enable from peripherals
OD: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Pad control register
pub const GPIO11 = Register(GPIO11_val).init(base_address + 0x30);

/// GPIO10
const GPIO10_val = packed struct {
/// SLEWFAST [0:0]
/// Slew rate control. 1 = Fast, 0 = Slow
SLEWFAST: u1 = 0,
/// SCHMITT [1:1]
/// Enable schmitt trigger
SCHMITT: u1 = 1,
/// PDE [2:2]
/// Pull down enable
PDE: u1 = 1,
/// PUE [3:3]
/// Pull up enable
PUE: u1 = 0,
/// DRIVE [4:5]
/// Drive strength.
DRIVE: u2 = 1,
/// IE [6:6]
/// Input enable
IE: u1 = 1,
/// OD [7:7]
/// Output disable. Has priority over output enable from peripherals
OD: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Pad control register
pub const GPIO10 = Register(GPIO10_val).init(base_address + 0x2c);

/// GPIO9
const GPIO9_val = packed struct {
/// SLEWFAST [0:0]
/// Slew rate control. 1 = Fast, 0 = Slow
SLEWFAST: u1 = 0,
/// SCHMITT [1:1]
/// Enable schmitt trigger
SCHMITT: u1 = 1,
/// PDE [2:2]
/// Pull down enable
PDE: u1 = 1,
/// PUE [3:3]
/// Pull up enable
PUE: u1 = 0,
/// DRIVE [4:5]
/// Drive strength.
DRIVE: u2 = 1,
/// IE [6:6]
/// Input enable
IE: u1 = 1,
/// OD [7:7]
/// Output disable. Has priority over output enable from peripherals
OD: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Pad control register
pub const GPIO9 = Register(GPIO9_val).init(base_address + 0x28);

/// GPIO8
const GPIO8_val = packed struct {
/// SLEWFAST [0:0]
/// Slew rate control. 1 = Fast, 0 = Slow
SLEWFAST: u1 = 0,
/// SCHMITT [1:1]
/// Enable schmitt trigger
SCHMITT: u1 = 1,
/// PDE [2:2]
/// Pull down enable
PDE: u1 = 1,
/// PUE [3:3]
/// Pull up enable
PUE: u1 = 0,
/// DRIVE [4:5]
/// Drive strength.
DRIVE: u2 = 1,
/// IE [6:6]
/// Input enable
IE: u1 = 1,
/// OD [7:7]
/// Output disable. Has priority over output enable from peripherals
OD: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Pad control register
pub const GPIO8 = Register(GPIO8_val).init(base_address + 0x24);

/// GPIO7
const GPIO7_val = packed struct {
/// SLEWFAST [0:0]
/// Slew rate control. 1 = Fast, 0 = Slow
SLEWFAST: u1 = 0,
/// SCHMITT [1:1]
/// Enable schmitt trigger
SCHMITT: u1 = 1,
/// PDE [2:2]
/// Pull down enable
PDE: u1 = 1,
/// PUE [3:3]
/// Pull up enable
PUE: u1 = 0,
/// DRIVE [4:5]
/// Drive strength.
DRIVE: u2 = 1,
/// IE [6:6]
/// Input enable
IE: u1 = 1,
/// OD [7:7]
/// Output disable. Has priority over output enable from peripherals
OD: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Pad control register
pub const GPIO7 = Register(GPIO7_val).init(base_address + 0x20);

/// GPIO6
const GPIO6_val = packed struct {
/// SLEWFAST [0:0]
/// Slew rate control. 1 = Fast, 0 = Slow
SLEWFAST: u1 = 0,
/// SCHMITT [1:1]
/// Enable schmitt trigger
SCHMITT: u1 = 1,
/// PDE [2:2]
/// Pull down enable
PDE: u1 = 1,
/// PUE [3:3]
/// Pull up enable
PUE: u1 = 0,
/// DRIVE [4:5]
/// Drive strength.
DRIVE: u2 = 1,
/// IE [6:6]
/// Input enable
IE: u1 = 1,
/// OD [7:7]
/// Output disable. Has priority over output enable from peripherals
OD: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Pad control register
pub const GPIO6 = Register(GPIO6_val).init(base_address + 0x1c);

/// GPIO5
const GPIO5_val = packed struct {
/// SLEWFAST [0:0]
/// Slew rate control. 1 = Fast, 0 = Slow
SLEWFAST: u1 = 0,
/// SCHMITT [1:1]
/// Enable schmitt trigger
SCHMITT: u1 = 1,
/// PDE [2:2]
/// Pull down enable
PDE: u1 = 1,
/// PUE [3:3]
/// Pull up enable
PUE: u1 = 0,
/// DRIVE [4:5]
/// Drive strength.
DRIVE: u2 = 1,
/// IE [6:6]
/// Input enable
IE: u1 = 1,
/// OD [7:7]
/// Output disable. Has priority over output enable from peripherals
OD: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Pad control register
pub const GPIO5 = Register(GPIO5_val).init(base_address + 0x18);

/// GPIO4
const GPIO4_val = packed struct {
/// SLEWFAST [0:0]
/// Slew rate control. 1 = Fast, 0 = Slow
SLEWFAST: u1 = 0,
/// SCHMITT [1:1]
/// Enable schmitt trigger
SCHMITT: u1 = 1,
/// PDE [2:2]
/// Pull down enable
PDE: u1 = 1,
/// PUE [3:3]
/// Pull up enable
PUE: u1 = 0,
/// DRIVE [4:5]
/// Drive strength.
DRIVE: u2 = 1,
/// IE [6:6]
/// Input enable
IE: u1 = 1,
/// OD [7:7]
/// Output disable. Has priority over output enable from peripherals
OD: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Pad control register
pub const GPIO4 = Register(GPIO4_val).init(base_address + 0x14);

/// GPIO3
const GPIO3_val = packed struct {
/// SLEWFAST [0:0]
/// Slew rate control. 1 = Fast, 0 = Slow
SLEWFAST: u1 = 0,
/// SCHMITT [1:1]
/// Enable schmitt trigger
SCHMITT: u1 = 1,
/// PDE [2:2]
/// Pull down enable
PDE: u1 = 1,
/// PUE [3:3]
/// Pull up enable
PUE: u1 = 0,
/// DRIVE [4:5]
/// Drive strength.
DRIVE: u2 = 1,
/// IE [6:6]
/// Input enable
IE: u1 = 1,
/// OD [7:7]
/// Output disable. Has priority over output enable from peripherals
OD: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Pad control register
pub const GPIO3 = Register(GPIO3_val).init(base_address + 0x10);

/// GPIO2
const GPIO2_val = packed struct {
/// SLEWFAST [0:0]
/// Slew rate control. 1 = Fast, 0 = Slow
SLEWFAST: u1 = 0,
/// SCHMITT [1:1]
/// Enable schmitt trigger
SCHMITT: u1 = 1,
/// PDE [2:2]
/// Pull down enable
PDE: u1 = 1,
/// PUE [3:3]
/// Pull up enable
PUE: u1 = 0,
/// DRIVE [4:5]
/// Drive strength.
DRIVE: u2 = 1,
/// IE [6:6]
/// Input enable
IE: u1 = 1,
/// OD [7:7]
/// Output disable. Has priority over output enable from peripherals
OD: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Pad control register
pub const GPIO2 = Register(GPIO2_val).init(base_address + 0xc);

/// GPIO1
const GPIO1_val = packed struct {
/// SLEWFAST [0:0]
/// Slew rate control. 1 = Fast, 0 = Slow
SLEWFAST: u1 = 0,
/// SCHMITT [1:1]
/// Enable schmitt trigger
SCHMITT: u1 = 1,
/// PDE [2:2]
/// Pull down enable
PDE: u1 = 1,
/// PUE [3:3]
/// Pull up enable
PUE: u1 = 0,
/// DRIVE [4:5]
/// Drive strength.
DRIVE: u2 = 1,
/// IE [6:6]
/// Input enable
IE: u1 = 1,
/// OD [7:7]
/// Output disable. Has priority over output enable from peripherals
OD: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Pad control register
pub const GPIO1 = Register(GPIO1_val).init(base_address + 0x8);

/// GPIO0
const GPIO0_val = packed struct {
/// SLEWFAST [0:0]
/// Slew rate control. 1 = Fast, 0 = Slow
SLEWFAST: u1 = 0,
/// SCHMITT [1:1]
/// Enable schmitt trigger
SCHMITT: u1 = 1,
/// PDE [2:2]
/// Pull down enable
PDE: u1 = 1,
/// PUE [3:3]
/// Pull up enable
PUE: u1 = 0,
/// DRIVE [4:5]
/// Drive strength.
DRIVE: u2 = 1,
/// IE [6:6]
/// Input enable
IE: u1 = 1,
/// OD [7:7]
/// Output disable. Has priority over output enable from peripherals
OD: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Pad control register
pub const GPIO0 = Register(GPIO0_val).init(base_address + 0x4);

/// VOLTAGE_SELECT
const VOLTAGE_SELECT_val = packed struct {
/// VOLTAGE_SELECT [0:0]
/// No description
VOLTAGE_SELECT: u1 = 0,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Voltage select. Per bank control
pub const VOLTAGE_SELECT = Register(VOLTAGE_SELECT_val).init(base_address + 0x0);
};

/// No description
pub const PADS_QSPI = struct {

const base_address = 0x40020000;
/// GPIO_QSPI_SS
const GPIO_QSPI_SS_val = packed struct {
/// SLEWFAST [0:0]
/// Slew rate control. 1 = Fast, 0 = Slow
SLEWFAST: u1 = 0,
/// SCHMITT [1:1]
/// Enable schmitt trigger
SCHMITT: u1 = 1,
/// PDE [2:2]
/// Pull down enable
PDE: u1 = 0,
/// PUE [3:3]
/// Pull up enable
PUE: u1 = 1,
/// DRIVE [4:5]
/// Drive strength.
DRIVE: u2 = 1,
/// IE [6:6]
/// Input enable
IE: u1 = 1,
/// OD [7:7]
/// Output disable. Has priority over output enable from peripherals
OD: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Pad control register
pub const GPIO_QSPI_SS = Register(GPIO_QSPI_SS_val).init(base_address + 0x18);

/// GPIO_QSPI_SD3
const GPIO_QSPI_SD3_val = packed struct {
/// SLEWFAST [0:0]
/// Slew rate control. 1 = Fast, 0 = Slow
SLEWFAST: u1 = 0,
/// SCHMITT [1:1]
/// Enable schmitt trigger
SCHMITT: u1 = 1,
/// PDE [2:2]
/// Pull down enable
PDE: u1 = 0,
/// PUE [3:3]
/// Pull up enable
PUE: u1 = 0,
/// DRIVE [4:5]
/// Drive strength.
DRIVE: u2 = 1,
/// IE [6:6]
/// Input enable
IE: u1 = 1,
/// OD [7:7]
/// Output disable. Has priority over output enable from peripherals
OD: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Pad control register
pub const GPIO_QSPI_SD3 = Register(GPIO_QSPI_SD3_val).init(base_address + 0x14);

/// GPIO_QSPI_SD2
const GPIO_QSPI_SD2_val = packed struct {
/// SLEWFAST [0:0]
/// Slew rate control. 1 = Fast, 0 = Slow
SLEWFAST: u1 = 0,
/// SCHMITT [1:1]
/// Enable schmitt trigger
SCHMITT: u1 = 1,
/// PDE [2:2]
/// Pull down enable
PDE: u1 = 0,
/// PUE [3:3]
/// Pull up enable
PUE: u1 = 0,
/// DRIVE [4:5]
/// Drive strength.
DRIVE: u2 = 1,
/// IE [6:6]
/// Input enable
IE: u1 = 1,
/// OD [7:7]
/// Output disable. Has priority over output enable from peripherals
OD: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Pad control register
pub const GPIO_QSPI_SD2 = Register(GPIO_QSPI_SD2_val).init(base_address + 0x10);

/// GPIO_QSPI_SD1
const GPIO_QSPI_SD1_val = packed struct {
/// SLEWFAST [0:0]
/// Slew rate control. 1 = Fast, 0 = Slow
SLEWFAST: u1 = 0,
/// SCHMITT [1:1]
/// Enable schmitt trigger
SCHMITT: u1 = 1,
/// PDE [2:2]
/// Pull down enable
PDE: u1 = 0,
/// PUE [3:3]
/// Pull up enable
PUE: u1 = 0,
/// DRIVE [4:5]
/// Drive strength.
DRIVE: u2 = 1,
/// IE [6:6]
/// Input enable
IE: u1 = 1,
/// OD [7:7]
/// Output disable. Has priority over output enable from peripherals
OD: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Pad control register
pub const GPIO_QSPI_SD1 = Register(GPIO_QSPI_SD1_val).init(base_address + 0xc);

/// GPIO_QSPI_SD0
const GPIO_QSPI_SD0_val = packed struct {
/// SLEWFAST [0:0]
/// Slew rate control. 1 = Fast, 0 = Slow
SLEWFAST: u1 = 0,
/// SCHMITT [1:1]
/// Enable schmitt trigger
SCHMITT: u1 = 1,
/// PDE [2:2]
/// Pull down enable
PDE: u1 = 0,
/// PUE [3:3]
/// Pull up enable
PUE: u1 = 0,
/// DRIVE [4:5]
/// Drive strength.
DRIVE: u2 = 1,
/// IE [6:6]
/// Input enable
IE: u1 = 1,
/// OD [7:7]
/// Output disable. Has priority over output enable from peripherals
OD: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Pad control register
pub const GPIO_QSPI_SD0 = Register(GPIO_QSPI_SD0_val).init(base_address + 0x8);

/// GPIO_QSPI_SCLK
const GPIO_QSPI_SCLK_val = packed struct {
/// SLEWFAST [0:0]
/// Slew rate control. 1 = Fast, 0 = Slow
SLEWFAST: u1 = 0,
/// SCHMITT [1:1]
/// Enable schmitt trigger
SCHMITT: u1 = 1,
/// PDE [2:2]
/// Pull down enable
PDE: u1 = 1,
/// PUE [3:3]
/// Pull up enable
PUE: u1 = 0,
/// DRIVE [4:5]
/// Drive strength.
DRIVE: u2 = 1,
/// IE [6:6]
/// Input enable
IE: u1 = 1,
/// OD [7:7]
/// Output disable. Has priority over output enable from peripherals
OD: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Pad control register
pub const GPIO_QSPI_SCLK = Register(GPIO_QSPI_SCLK_val).init(base_address + 0x4);

/// VOLTAGE_SELECT
const VOLTAGE_SELECT_val = packed struct {
/// VOLTAGE_SELECT [0:0]
/// No description
VOLTAGE_SELECT: u1 = 0,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Voltage select. Per bank control
pub const VOLTAGE_SELECT = Register(VOLTAGE_SELECT_val).init(base_address + 0x0);
};

/// Controls the crystal oscillator
pub const XOSC = struct {

const base_address = 0x40024000;
/// COUNT
const COUNT_val = packed struct {
/// COUNT [0:7]
/// No description
COUNT: u8 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// A down counter running at the xosc frequency which counts to zero and stops.\n
pub const COUNT = Register(COUNT_val).init(base_address + 0x1c);

/// STARTUP
const STARTUP_val = packed struct {
/// DELAY [0:13]
/// in multiples of 256*xtal_period
DELAY: u14 = 0,
/// unused [14:19]
_unused14: u2 = 0,
_unused16: u4 = 0,
/// X4 [20:20]
/// Multiplies the startup_delay by 4. This is of little value to the user given that the delay can be programmed directly
X4: u1 = 0,
/// unused [21:31]
_unused21: u3 = 0,
_unused24: u8 = 0,
};
/// Controls the startup delay
pub const STARTUP = Register(STARTUP_val).init(base_address + 0xc);

/// DORMANT
const DORMANT_val = packed struct {
DORMANT_0: u8 = 0,
DORMANT_1: u8 = 0,
DORMANT_2: u8 = 0,
DORMANT_3: u8 = 0,
};
/// Crystal Oscillator pause control\n
pub const DORMANT = Register(DORMANT_val).init(base_address + 0x8);

/// STATUS
const STATUS_val = packed struct {
/// FREQ_RANGE [0:1]
/// The current frequency range setting, always reads 0
FREQ_RANGE: u2 = 0,
/// unused [2:11]
_unused2: u6 = 0,
_unused8: u4 = 0,
/// ENABLED [12:12]
/// Oscillator is enabled but not necessarily running and stable, resets to 0
ENABLED: u1 = 0,
/// unused [13:23]
_unused13: u3 = 0,
_unused16: u8 = 0,
/// BADWRITE [24:24]
/// An invalid value has been written to CTRL_ENABLE or CTRL_FREQ_RANGE or DORMANT
BADWRITE: u1 = 0,
/// unused [25:30]
_unused25: u6 = 0,
/// STABLE [31:31]
/// Oscillator is running and stable
STABLE: u1 = 0,
};
/// Crystal Oscillator Status
pub const STATUS = Register(STATUS_val).init(base_address + 0x4);

/// CTRL
const CTRL_val = packed struct {
/// FREQ_RANGE [0:11]
/// Frequency range. This resets to 0xAA0 and cannot be changed.
FREQ_RANGE: u12 = 0,
/// ENABLE [12:23]
/// On power-up this field is initialised to DISABLE and the chip runs from the ROSC.\n
ENABLE: u12 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// Crystal Oscillator Control
pub const CTRL = Register(CTRL_val).init(base_address + 0x0);
};

/// No description
pub const PLL_SYS = struct {

const base_address = 0x40028000;
/// PRIM
const PRIM_val = packed struct {
/// unused [0:11]
_unused0: u8 = 0,
_unused8: u4 = 0,
/// POSTDIV2 [12:14]
/// divide by 1-7
POSTDIV2: u3 = 7,
/// unused [15:15]
_unused15: u1 = 0,
/// POSTDIV1 [16:18]
/// divide by 1-7
POSTDIV1: u3 = 7,
/// unused [19:31]
_unused19: u5 = 0,
_unused24: u8 = 0,
};
/// Controls the PLL post dividers for the primary output\n
pub const PRIM = Register(PRIM_val).init(base_address + 0xc);

/// FBDIV_INT
const FBDIV_INT_val = packed struct {
/// FBDIV_INT [0:11]
/// see ctrl reg description for constraints
FBDIV_INT: u12 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Feedback divisor\n
pub const FBDIV_INT = Register(FBDIV_INT_val).init(base_address + 0x8);

/// PWR
const PWR_val = packed struct {
/// PD [0:0]
/// PLL powerdown\n
PD: u1 = 1,
/// unused [1:1]
_unused1: u1 = 0,
/// DSMPD [2:2]
/// PLL DSM powerdown\n
DSMPD: u1 = 1,
/// POSTDIVPD [3:3]
/// PLL post divider powerdown\n
POSTDIVPD: u1 = 1,
/// unused [4:4]
_unused4: u1 = 0,
/// VCOPD [5:5]
/// PLL VCO powerdown\n
VCOPD: u1 = 1,
/// unused [6:31]
_unused6: u2 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Controls the PLL power modes.
pub const PWR = Register(PWR_val).init(base_address + 0x4);

/// CS
const CS_val = packed struct {
/// REFDIV [0:5]
/// Divides the PLL input reference clock.\n
REFDIV: u6 = 1,
/// unused [6:7]
_unused6: u2 = 0,
/// BYPASS [8:8]
/// Passes the reference clock to the output instead of the divided VCO. The VCO continues to run so the user can switch between the reference clock and the divided VCO but the output will glitch when doing so.
BYPASS: u1 = 0,
/// unused [9:30]
_unused9: u7 = 0,
_unused16: u8 = 0,
_unused24: u7 = 0,
/// LOCK [31:31]
/// PLL is locked
LOCK: u1 = 0,
};
/// Control and Status\n
pub const CS = Register(CS_val).init(base_address + 0x0);
};

/// No description
pub const PLL_USB = struct {

const base_address = 0x4002c000;
/// PRIM
const PRIM_val = packed struct {
/// unused [0:11]
_unused0: u8 = 0,
_unused8: u4 = 0,
/// POSTDIV2 [12:14]
/// divide by 1-7
POSTDIV2: u3 = 7,
/// unused [15:15]
_unused15: u1 = 0,
/// POSTDIV1 [16:18]
/// divide by 1-7
POSTDIV1: u3 = 7,
/// unused [19:31]
_unused19: u5 = 0,
_unused24: u8 = 0,
};
/// Controls the PLL post dividers for the primary output\n
pub const PRIM = Register(PRIM_val).init(base_address + 0xc);

/// FBDIV_INT
const FBDIV_INT_val = packed struct {
/// FBDIV_INT [0:11]
/// see ctrl reg description for constraints
FBDIV_INT: u12 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Feedback divisor\n
pub const FBDIV_INT = Register(FBDIV_INT_val).init(base_address + 0x8);

/// PWR
const PWR_val = packed struct {
/// PD [0:0]
/// PLL powerdown\n
PD: u1 = 1,
/// unused [1:1]
_unused1: u1 = 0,
/// DSMPD [2:2]
/// PLL DSM powerdown\n
DSMPD: u1 = 1,
/// POSTDIVPD [3:3]
/// PLL post divider powerdown\n
POSTDIVPD: u1 = 1,
/// unused [4:4]
_unused4: u1 = 0,
/// VCOPD [5:5]
/// PLL VCO powerdown\n
VCOPD: u1 = 1,
/// unused [6:31]
_unused6: u2 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Controls the PLL power modes.
pub const PWR = Register(PWR_val).init(base_address + 0x4);

/// CS
const CS_val = packed struct {
/// REFDIV [0:5]
/// Divides the PLL input reference clock.\n
REFDIV: u6 = 1,
/// unused [6:7]
_unused6: u2 = 0,
/// BYPASS [8:8]
/// Passes the reference clock to the output instead of the divided VCO. The VCO continues to run so the user can switch between the reference clock and the divided VCO but the output will glitch when doing so.
BYPASS: u1 = 0,
/// unused [9:30]
_unused9: u7 = 0,
_unused16: u8 = 0,
_unused24: u7 = 0,
/// LOCK [31:31]
/// PLL is locked
LOCK: u1 = 0,
};
/// Control and Status\n
pub const CS = Register(CS_val).init(base_address + 0x0);
};

/// Register block for busfabric control signals and performance counters
pub const BUSCTRL = struct {

const base_address = 0x40030000;
/// PERFSEL3
const PERFSEL3_val = packed struct {
/// PERFSEL3 [0:4]
/// Select an event for PERFCTR3. Count either contested accesses, or all accesses, on a downstream port of the main crossbar.
PERFSEL3: u5 = 31,
/// unused [5:31]
_unused5: u3 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Bus fabric performance event select for PERFCTR3
pub const PERFSEL3 = Register(PERFSEL3_val).init(base_address + 0x24);

/// PERFCTR3
const PERFCTR3_val = packed struct {
/// PERFCTR3 [0:23]
/// Busfabric saturating performance counter 3\n
PERFCTR3: u24 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// Bus fabric performance counter 3
pub const PERFCTR3 = Register(PERFCTR3_val).init(base_address + 0x20);

/// PERFSEL2
const PERFSEL2_val = packed struct {
/// PERFSEL2 [0:4]
/// Select an event for PERFCTR2. Count either contested accesses, or all accesses, on a downstream port of the main crossbar.
PERFSEL2: u5 = 31,
/// unused [5:31]
_unused5: u3 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Bus fabric performance event select for PERFCTR2
pub const PERFSEL2 = Register(PERFSEL2_val).init(base_address + 0x1c);

/// PERFCTR2
const PERFCTR2_val = packed struct {
/// PERFCTR2 [0:23]
/// Busfabric saturating performance counter 2\n
PERFCTR2: u24 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// Bus fabric performance counter 2
pub const PERFCTR2 = Register(PERFCTR2_val).init(base_address + 0x18);

/// PERFSEL1
const PERFSEL1_val = packed struct {
/// PERFSEL1 [0:4]
/// Select an event for PERFCTR1. Count either contested accesses, or all accesses, on a downstream port of the main crossbar.
PERFSEL1: u5 = 31,
/// unused [5:31]
_unused5: u3 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Bus fabric performance event select for PERFCTR1
pub const PERFSEL1 = Register(PERFSEL1_val).init(base_address + 0x14);

/// PERFCTR1
const PERFCTR1_val = packed struct {
/// PERFCTR1 [0:23]
/// Busfabric saturating performance counter 1\n
PERFCTR1: u24 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// Bus fabric performance counter 1
pub const PERFCTR1 = Register(PERFCTR1_val).init(base_address + 0x10);

/// PERFSEL0
const PERFSEL0_val = packed struct {
/// PERFSEL0 [0:4]
/// Select an event for PERFCTR0. Count either contested accesses, or all accesses, on a downstream port of the main crossbar.
PERFSEL0: u5 = 31,
/// unused [5:31]
_unused5: u3 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Bus fabric performance event select for PERFCTR0
pub const PERFSEL0 = Register(PERFSEL0_val).init(base_address + 0xc);

/// PERFCTR0
const PERFCTR0_val = packed struct {
/// PERFCTR0 [0:23]
/// Busfabric saturating performance counter 0\n
PERFCTR0: u24 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// Bus fabric performance counter 0
pub const PERFCTR0 = Register(PERFCTR0_val).init(base_address + 0x8);

/// BUS_PRIORITY_ACK
const BUS_PRIORITY_ACK_val = packed struct {
/// BUS_PRIORITY_ACK [0:0]
/// Goes to 1 once all arbiters have registered the new global priority levels.\n
BUS_PRIORITY_ACK: u1 = 0,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Bus priority acknowledge
pub const BUS_PRIORITY_ACK = Register(BUS_PRIORITY_ACK_val).init(base_address + 0x4);

/// BUS_PRIORITY
const BUS_PRIORITY_val = packed struct {
/// PROC0 [0:0]
/// 0 - low priority, 1 - high priority
PROC0: u1 = 0,
/// unused [1:3]
_unused1: u3 = 0,
/// PROC1 [4:4]
/// 0 - low priority, 1 - high priority
PROC1: u1 = 0,
/// unused [5:7]
_unused5: u3 = 0,
/// DMA_R [8:8]
/// 0 - low priority, 1 - high priority
DMA_R: u1 = 0,
/// unused [9:11]
_unused9: u3 = 0,
/// DMA_W [12:12]
/// 0 - low priority, 1 - high priority
DMA_W: u1 = 0,
/// unused [13:31]
_unused13: u3 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Set the priority of each master for bus arbitration.
pub const BUS_PRIORITY = Register(BUS_PRIORITY_val).init(base_address + 0x0);
};

/// No description
pub const UART0 = struct {

const base_address = 0x40034000;
/// UARTPCELLID3
const UARTPCELLID3_val = packed struct {
/// UARTPCELLID3 [0:7]
/// These bits read back as 0xB1
UARTPCELLID3: u8 = 177,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// UARTPCellID3 Register
pub const UARTPCELLID3 = Register(UARTPCELLID3_val).init(base_address + 0xffc);

/// UARTPCELLID2
const UARTPCELLID2_val = packed struct {
/// UARTPCELLID2 [0:7]
/// These bits read back as 0x05
UARTPCELLID2: u8 = 5,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// UARTPCellID2 Register
pub const UARTPCELLID2 = Register(UARTPCELLID2_val).init(base_address + 0xff8);

/// UARTPCELLID1
const UARTPCELLID1_val = packed struct {
/// UARTPCELLID1 [0:7]
/// These bits read back as 0xF0
UARTPCELLID1: u8 = 240,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// UARTPCellID1 Register
pub const UARTPCELLID1 = Register(UARTPCELLID1_val).init(base_address + 0xff4);

/// UARTPCELLID0
const UARTPCELLID0_val = packed struct {
/// UARTPCELLID0 [0:7]
/// These bits read back as 0x0D
UARTPCELLID0: u8 = 13,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// UARTPCellID0 Register
pub const UARTPCELLID0 = Register(UARTPCELLID0_val).init(base_address + 0xff0);

/// UARTPERIPHID3
const UARTPERIPHID3_val = packed struct {
/// CONFIGURATION [0:7]
/// These bits read back as 0x00
CONFIGURATION: u8 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// UARTPeriphID3 Register
pub const UARTPERIPHID3 = Register(UARTPERIPHID3_val).init(base_address + 0xfec);

/// UARTPERIPHID2
const UARTPERIPHID2_val = packed struct {
/// DESIGNER1 [0:3]
/// These bits read back as 0x4
DESIGNER1: u4 = 4,
/// REVISION [4:7]
/// This field depends on the revision of the UART: r1p0 0x0 r1p1 0x1 r1p3 0x2 r1p4 0x2 r1p5 0x3
REVISION: u4 = 3,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// UARTPeriphID2 Register
pub const UARTPERIPHID2 = Register(UARTPERIPHID2_val).init(base_address + 0xfe8);

/// UARTPERIPHID1
const UARTPERIPHID1_val = packed struct {
/// PARTNUMBER1 [0:3]
/// These bits read back as 0x0
PARTNUMBER1: u4 = 0,
/// DESIGNER0 [4:7]
/// These bits read back as 0x1
DESIGNER0: u4 = 1,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// UARTPeriphID1 Register
pub const UARTPERIPHID1 = Register(UARTPERIPHID1_val).init(base_address + 0xfe4);

/// UARTPERIPHID0
const UARTPERIPHID0_val = packed struct {
/// PARTNUMBER0 [0:7]
/// These bits read back as 0x11
PARTNUMBER0: u8 = 17,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// UARTPeriphID0 Register
pub const UARTPERIPHID0 = Register(UARTPERIPHID0_val).init(base_address + 0xfe0);

/// UARTDMACR
const UARTDMACR_val = packed struct {
/// RXDMAE [0:0]
/// Receive DMA enable. If this bit is set to 1, DMA for the receive FIFO is enabled.
RXDMAE: u1 = 0,
/// TXDMAE [1:1]
/// Transmit DMA enable. If this bit is set to 1, DMA for the transmit FIFO is enabled.
TXDMAE: u1 = 0,
/// DMAONERR [2:2]
/// DMA on error. If this bit is set to 1, the DMA receive request outputs, UARTRXDMASREQ or UARTRXDMABREQ, are disabled when the UART error interrupt is asserted.
DMAONERR: u1 = 0,
/// unused [3:31]
_unused3: u5 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// DMA Control Register, UARTDMACR
pub const UARTDMACR = Register(UARTDMACR_val).init(base_address + 0x48);

/// UARTICR
const UARTICR_val = packed struct {
/// RIMIC [0:0]
/// nUARTRI modem interrupt clear. Clears the UARTRIINTR interrupt.
RIMIC: u1 = 0,
/// CTSMIC [1:1]
/// nUARTCTS modem interrupt clear. Clears the UARTCTSINTR interrupt.
CTSMIC: u1 = 0,
/// DCDMIC [2:2]
/// nUARTDCD modem interrupt clear. Clears the UARTDCDINTR interrupt.
DCDMIC: u1 = 0,
/// DSRMIC [3:3]
/// nUARTDSR modem interrupt clear. Clears the UARTDSRINTR interrupt.
DSRMIC: u1 = 0,
/// RXIC [4:4]
/// Receive interrupt clear. Clears the UARTRXINTR interrupt.
RXIC: u1 = 0,
/// TXIC [5:5]
/// Transmit interrupt clear. Clears the UARTTXINTR interrupt.
TXIC: u1 = 0,
/// RTIC [6:6]
/// Receive timeout interrupt clear. Clears the UARTRTINTR interrupt.
RTIC: u1 = 0,
/// FEIC [7:7]
/// Framing error interrupt clear. Clears the UARTFEINTR interrupt.
FEIC: u1 = 0,
/// PEIC [8:8]
/// Parity error interrupt clear. Clears the UARTPEINTR interrupt.
PEIC: u1 = 0,
/// BEIC [9:9]
/// Break error interrupt clear. Clears the UARTBEINTR interrupt.
BEIC: u1 = 0,
/// OEIC [10:10]
/// Overrun error interrupt clear. Clears the UARTOEINTR interrupt.
OEIC: u1 = 0,
/// unused [11:31]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Interrupt Clear Register, UARTICR
pub const UARTICR = Register(UARTICR_val).init(base_address + 0x44);

/// UARTMIS
const UARTMIS_val = packed struct {
/// RIMMIS [0:0]
/// nUARTRI modem masked interrupt status. Returns the masked interrupt state of the UARTRIINTR interrupt.
RIMMIS: u1 = 0,
/// CTSMMIS [1:1]
/// nUARTCTS modem masked interrupt status. Returns the masked interrupt state of the UARTCTSINTR interrupt.
CTSMMIS: u1 = 0,
/// DCDMMIS [2:2]
/// nUARTDCD modem masked interrupt status. Returns the masked interrupt state of the UARTDCDINTR interrupt.
DCDMMIS: u1 = 0,
/// DSRMMIS [3:3]
/// nUARTDSR modem masked interrupt status. Returns the masked interrupt state of the UARTDSRINTR interrupt.
DSRMMIS: u1 = 0,
/// RXMIS [4:4]
/// Receive masked interrupt status. Returns the masked interrupt state of the UARTRXINTR interrupt.
RXMIS: u1 = 0,
/// TXMIS [5:5]
/// Transmit masked interrupt status. Returns the masked interrupt state of the UARTTXINTR interrupt.
TXMIS: u1 = 0,
/// RTMIS [6:6]
/// Receive timeout masked interrupt status. Returns the masked interrupt state of the UARTRTINTR interrupt.
RTMIS: u1 = 0,
/// FEMIS [7:7]
/// Framing error masked interrupt status. Returns the masked interrupt state of the UARTFEINTR interrupt.
FEMIS: u1 = 0,
/// PEMIS [8:8]
/// Parity error masked interrupt status. Returns the masked interrupt state of the UARTPEINTR interrupt.
PEMIS: u1 = 0,
/// BEMIS [9:9]
/// Break error masked interrupt status. Returns the masked interrupt state of the UARTBEINTR interrupt.
BEMIS: u1 = 0,
/// OEMIS [10:10]
/// Overrun error masked interrupt status. Returns the masked interrupt state of the UARTOEINTR interrupt.
OEMIS: u1 = 0,
/// unused [11:31]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Masked Interrupt Status Register, UARTMIS
pub const UARTMIS = Register(UARTMIS_val).init(base_address + 0x40);

/// UARTRIS
const UARTRIS_val = packed struct {
/// RIRMIS [0:0]
/// nUARTRI modem interrupt status. Returns the raw interrupt state of the UARTRIINTR interrupt.
RIRMIS: u1 = 0,
/// CTSRMIS [1:1]
/// nUARTCTS modem interrupt status. Returns the raw interrupt state of the UARTCTSINTR interrupt.
CTSRMIS: u1 = 0,
/// DCDRMIS [2:2]
/// nUARTDCD modem interrupt status. Returns the raw interrupt state of the UARTDCDINTR interrupt.
DCDRMIS: u1 = 0,
/// DSRRMIS [3:3]
/// nUARTDSR modem interrupt status. Returns the raw interrupt state of the UARTDSRINTR interrupt.
DSRRMIS: u1 = 0,
/// RXRIS [4:4]
/// Receive interrupt status. Returns the raw interrupt state of the UARTRXINTR interrupt.
RXRIS: u1 = 0,
/// TXRIS [5:5]
/// Transmit interrupt status. Returns the raw interrupt state of the UARTTXINTR interrupt.
TXRIS: u1 = 0,
/// RTRIS [6:6]
/// Receive timeout interrupt status. Returns the raw interrupt state of the UARTRTINTR interrupt. a
RTRIS: u1 = 0,
/// FERIS [7:7]
/// Framing error interrupt status. Returns the raw interrupt state of the UARTFEINTR interrupt.
FERIS: u1 = 0,
/// PERIS [8:8]
/// Parity error interrupt status. Returns the raw interrupt state of the UARTPEINTR interrupt.
PERIS: u1 = 0,
/// BERIS [9:9]
/// Break error interrupt status. Returns the raw interrupt state of the UARTBEINTR interrupt.
BERIS: u1 = 0,
/// OERIS [10:10]
/// Overrun error interrupt status. Returns the raw interrupt state of the UARTOEINTR interrupt.
OERIS: u1 = 0,
/// unused [11:31]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Raw Interrupt Status Register, UARTRIS
pub const UARTRIS = Register(UARTRIS_val).init(base_address + 0x3c);

/// UARTIMSC
const UARTIMSC_val = packed struct {
/// RIMIM [0:0]
/// nUARTRI modem interrupt mask. A read returns the current mask for the UARTRIINTR interrupt. On a write of 1, the mask of the UARTRIINTR interrupt is set. A write of 0 clears the mask.
RIMIM: u1 = 0,
/// CTSMIM [1:1]
/// nUARTCTS modem interrupt mask. A read returns the current mask for the UARTCTSINTR interrupt. On a write of 1, the mask of the UARTCTSINTR interrupt is set. A write of 0 clears the mask.
CTSMIM: u1 = 0,
/// DCDMIM [2:2]
/// nUARTDCD modem interrupt mask. A read returns the current mask for the UARTDCDINTR interrupt. On a write of 1, the mask of the UARTDCDINTR interrupt is set. A write of 0 clears the mask.
DCDMIM: u1 = 0,
/// DSRMIM [3:3]
/// nUARTDSR modem interrupt mask. A read returns the current mask for the UARTDSRINTR interrupt. On a write of 1, the mask of the UARTDSRINTR interrupt is set. A write of 0 clears the mask.
DSRMIM: u1 = 0,
/// RXIM [4:4]
/// Receive interrupt mask. A read returns the current mask for the UARTRXINTR interrupt. On a write of 1, the mask of the UARTRXINTR interrupt is set. A write of 0 clears the mask.
RXIM: u1 = 0,
/// TXIM [5:5]
/// Transmit interrupt mask. A read returns the current mask for the UARTTXINTR interrupt. On a write of 1, the mask of the UARTTXINTR interrupt is set. A write of 0 clears the mask.
TXIM: u1 = 0,
/// RTIM [6:6]
/// Receive timeout interrupt mask. A read returns the current mask for the UARTRTINTR interrupt. On a write of 1, the mask of the UARTRTINTR interrupt is set. A write of 0 clears the mask.
RTIM: u1 = 0,
/// FEIM [7:7]
/// Framing error interrupt mask. A read returns the current mask for the UARTFEINTR interrupt. On a write of 1, the mask of the UARTFEINTR interrupt is set. A write of 0 clears the mask.
FEIM: u1 = 0,
/// PEIM [8:8]
/// Parity error interrupt mask. A read returns the current mask for the UARTPEINTR interrupt. On a write of 1, the mask of the UARTPEINTR interrupt is set. A write of 0 clears the mask.
PEIM: u1 = 0,
/// BEIM [9:9]
/// Break error interrupt mask. A read returns the current mask for the UARTBEINTR interrupt. On a write of 1, the mask of the UARTBEINTR interrupt is set. A write of 0 clears the mask.
BEIM: u1 = 0,
/// OEIM [10:10]
/// Overrun error interrupt mask. A read returns the current mask for the UARTOEINTR interrupt. On a write of 1, the mask of the UARTOEINTR interrupt is set. A write of 0 clears the mask.
OEIM: u1 = 0,
/// unused [11:31]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Interrupt Mask Set/Clear Register, UARTIMSC
pub const UARTIMSC = Register(UARTIMSC_val).init(base_address + 0x38);

/// UARTIFLS
const UARTIFLS_val = packed struct {
/// TXIFLSEL [0:2]
/// Transmit interrupt FIFO level select. The trigger points for the transmit interrupt are as follows: b000 = Transmit FIFO becomes &lt;= 1 / 8 full b001 = Transmit FIFO becomes &lt;= 1 / 4 full b010 = Transmit FIFO becomes &lt;= 1 / 2 full b011 = Transmit FIFO becomes &lt;= 3 / 4 full b100 = Transmit FIFO becomes &lt;= 7 / 8 full b101-b111 = reserved.
TXIFLSEL: u3 = 2,
/// RXIFLSEL [3:5]
/// Receive interrupt FIFO level select. The trigger points for the receive interrupt are as follows: b000 = Receive FIFO becomes &gt;= 1 / 8 full b001 = Receive FIFO becomes &gt;= 1 / 4 full b010 = Receive FIFO becomes &gt;= 1 / 2 full b011 = Receive FIFO becomes &gt;= 3 / 4 full b100 = Receive FIFO becomes &gt;= 7 / 8 full b101-b111 = reserved.
RXIFLSEL: u3 = 2,
/// unused [6:31]
_unused6: u2 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Interrupt FIFO Level Select Register, UARTIFLS
pub const UARTIFLS = Register(UARTIFLS_val).init(base_address + 0x34);

/// UARTCR
const UARTCR_val = packed struct {
/// UARTEN [0:0]
/// UART enable: 0 = UART is disabled. If the UART is disabled in the middle of transmission or reception, it completes the current character before stopping. 1 = the UART is enabled. Data transmission and reception occurs for either UART signals or SIR signals depending on the setting of the SIREN bit.
UARTEN: u1 = 0,
/// SIREN [1:1]
/// SIR enable: 0 = IrDA SIR ENDEC is disabled. nSIROUT remains LOW (no light pulse generated), and signal transitions on SIRIN have no effect. 1 = IrDA SIR ENDEC is enabled. Data is transmitted and received on nSIROUT and SIRIN. UARTTXD remains HIGH, in the marking state. Signal transitions on UARTRXD or modem status inputs have no effect. This bit has no effect if the UARTEN bit disables the UART.
SIREN: u1 = 0,
/// SIRLP [2:2]
/// SIR low-power IrDA mode. This bit selects the IrDA encoding mode. If this bit is cleared to 0, low-level bits are transmitted as an active high pulse with a width of 3 / 16th of the bit period. If this bit is set to 1, low-level bits are transmitted with a pulse width that is 3 times the period of the IrLPBaud16 input signal, regardless of the selected bit rate. Setting this bit uses less power, but might reduce transmission distances.
SIRLP: u1 = 0,
/// unused [3:6]
_unused3: u4 = 0,
/// LBE [7:7]
/// Loopback enable. If this bit is set to 1 and the SIREN bit is set to 1 and the SIRTEST bit in the Test Control Register, UARTTCR is set to 1, then the nSIROUT path is inverted, and fed through to the SIRIN path. The SIRTEST bit in the test register must be set to 1 to override the normal half-duplex SIR operation. This must be the requirement for accessing the test registers during normal operation, and SIRTEST must be cleared to 0 when loopback testing is finished. This feature reduces the amount of external coupling required during system test. If this bit is set to 1, and the SIRTEST bit is set to 0, the UARTTXD path is fed through to the UARTRXD path. In either SIR mode or UART mode, when this bit is set, the modem outputs are also fed through to the modem inputs. This bit is cleared to 0 on reset, to disable loopback.
LBE: u1 = 0,
/// TXE [8:8]
/// Transmit enable. If this bit is set to 1, the transmit section of the UART is enabled. Data transmission occurs for either UART signals, or SIR signals depending on the setting of the SIREN bit. When the UART is disabled in the middle of transmission, it completes the current character before stopping.
TXE: u1 = 1,
/// RXE [9:9]
/// Receive enable. If this bit is set to 1, the receive section of the UART is enabled. Data reception occurs for either UART signals or SIR signals depending on the setting of the SIREN bit. When the UART is disabled in the middle of reception, it completes the current character before stopping.
RXE: u1 = 1,
/// DTR [10:10]
/// Data transmit ready. This bit is the complement of the UART data transmit ready, nUARTDTR, modem status output. That is, when the bit is programmed to a 1 then nUARTDTR is LOW.
DTR: u1 = 0,
/// RTS [11:11]
/// Request to send. This bit is the complement of the UART request to send, nUARTRTS, modem status output. That is, when the bit is programmed to a 1 then nUARTRTS is LOW.
RTS: u1 = 0,
/// OUT1 [12:12]
/// This bit is the complement of the UART Out1 (nUARTOut1) modem status output. That is, when the bit is programmed to a 1 the output is 0. For DTE this can be used as Data Carrier Detect (DCD).
OUT1: u1 = 0,
/// OUT2 [13:13]
/// This bit is the complement of the UART Out2 (nUARTOut2) modem status output. That is, when the bit is programmed to a 1, the output is 0. For DTE this can be used as Ring Indicator (RI).
OUT2: u1 = 0,
/// RTSEN [14:14]
/// RTS hardware flow control enable. If this bit is set to 1, RTS hardware flow control is enabled. Data is only requested when there is space in the receive FIFO for it to be received.
RTSEN: u1 = 0,
/// CTSEN [15:15]
/// CTS hardware flow control enable. If this bit is set to 1, CTS hardware flow control is enabled. Data is only transmitted when the nUARTCTS signal is asserted.
CTSEN: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Control Register, UARTCR
pub const UARTCR = Register(UARTCR_val).init(base_address + 0x30);

/// UARTLCR_H
const UARTLCR_H_val = packed struct {
/// BRK [0:0]
/// Send break. If this bit is set to 1, a low-level is continually output on the UARTTXD output, after completing transmission of the current character. For the proper execution of the break command, the software must set this bit for at least two complete frames. For normal use, this bit must be cleared to 0.
BRK: u1 = 0,
/// PEN [1:1]
/// Parity enable: 0 = parity is disabled and no parity bit added to the data frame 1 = parity checking and generation is enabled.
PEN: u1 = 0,
/// EPS [2:2]
/// Even parity select. Controls the type of parity the UART uses during transmission and reception: 0 = odd parity. The UART generates or checks for an odd number of 1s in the data and parity bits. 1 = even parity. The UART generates or checks for an even number of 1s in the data and parity bits. This bit has no effect when the PEN bit disables parity checking and generation.
EPS: u1 = 0,
/// STP2 [3:3]
/// Two stop bits select. If this bit is set to 1, two stop bits are transmitted at the end of the frame. The receive logic does not check for two stop bits being received.
STP2: u1 = 0,
/// FEN [4:4]
/// Enable FIFOs: 0 = FIFOs are disabled (character mode) that is, the FIFOs become 1-byte-deep holding registers 1 = transmit and receive FIFO buffers are enabled (FIFO mode).
FEN: u1 = 0,
/// WLEN [5:6]
/// Word length. These bits indicate the number of data bits transmitted or received in a frame as follows: b11 = 8 bits b10 = 7 bits b01 = 6 bits b00 = 5 bits.
WLEN: u2 = 0,
/// SPS [7:7]
/// Stick parity select. 0 = stick parity is disabled 1 = either: * if the EPS bit is 0 then the parity bit is transmitted and checked as a 1 * if the EPS bit is 1 then the parity bit is transmitted and checked as a 0. This bit has no effect when the PEN bit disables parity checking and generation.
SPS: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Line Control Register, UARTLCR_H
pub const UARTLCR_H = Register(UARTLCR_H_val).init(base_address + 0x2c);

/// UARTFBRD
const UARTFBRD_val = packed struct {
/// BAUD_DIVFRAC [0:5]
/// The fractional baud rate divisor. These bits are cleared to 0 on reset.
BAUD_DIVFRAC: u6 = 0,
/// unused [6:31]
_unused6: u2 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Fractional Baud Rate Register, UARTFBRD
pub const UARTFBRD = Register(UARTFBRD_val).init(base_address + 0x28);

/// UARTIBRD
const UARTIBRD_val = packed struct {
/// BAUD_DIVINT [0:15]
/// The integer baud rate divisor. These bits are cleared to 0 on reset.
BAUD_DIVINT: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Integer Baud Rate Register, UARTIBRD
pub const UARTIBRD = Register(UARTIBRD_val).init(base_address + 0x24);

/// UARTILPR
const UARTILPR_val = packed struct {
/// ILPDVSR [0:7]
/// 8-bit low-power divisor value. These bits are cleared to 0 at reset.
ILPDVSR: u8 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// IrDA Low-Power Counter Register, UARTILPR
pub const UARTILPR = Register(UARTILPR_val).init(base_address + 0x20);

/// UARTFR
const UARTFR_val = packed struct {
/// CTS [0:0]
/// Clear to send. This bit is the complement of the UART clear to send, nUARTCTS, modem status input. That is, the bit is 1 when nUARTCTS is LOW.
CTS: u1 = 0,
/// DSR [1:1]
/// Data set ready. This bit is the complement of the UART data set ready, nUARTDSR, modem status input. That is, the bit is 1 when nUARTDSR is LOW.
DSR: u1 = 0,
/// DCD [2:2]
/// Data carrier detect. This bit is the complement of the UART data carrier detect, nUARTDCD, modem status input. That is, the bit is 1 when nUARTDCD is LOW.
DCD: u1 = 0,
/// BUSY [3:3]
/// UART busy. If this bit is set to 1, the UART is busy transmitting data. This bit remains set until the complete byte, including all the stop bits, has been sent from the shift register. This bit is set as soon as the transmit FIFO becomes non-empty, regardless of whether the UART is enabled or not.
BUSY: u1 = 0,
/// RXFE [4:4]
/// Receive FIFO empty. The meaning of this bit depends on the state of the FEN bit in the UARTLCR_H Register. If the FIFO is disabled, this bit is set when the receive holding register is empty. If the FIFO is enabled, the RXFE bit is set when the receive FIFO is empty.
RXFE: u1 = 1,
/// TXFF [5:5]
/// Transmit FIFO full. The meaning of this bit depends on the state of the FEN bit in the UARTLCR_H Register. If the FIFO is disabled, this bit is set when the transmit holding register is full. If the FIFO is enabled, the TXFF bit is set when the transmit FIFO is full.
TXFF: u1 = 0,
/// RXFF [6:6]
/// Receive FIFO full. The meaning of this bit depends on the state of the FEN bit in the UARTLCR_H Register. If the FIFO is disabled, this bit is set when the receive holding register is full. If the FIFO is enabled, the RXFF bit is set when the receive FIFO is full.
RXFF: u1 = 0,
/// TXFE [7:7]
/// Transmit FIFO empty. The meaning of this bit depends on the state of the FEN bit in the Line Control Register, UARTLCR_H. If the FIFO is disabled, this bit is set when the transmit holding register is empty. If the FIFO is enabled, the TXFE bit is set when the transmit FIFO is empty. This bit does not indicate if there is data in the transmit shift register.
TXFE: u1 = 1,
/// RI [8:8]
/// Ring indicator. This bit is the complement of the UART ring indicator, nUARTRI, modem status input. That is, the bit is 1 when nUARTRI is LOW.
RI: u1 = 0,
/// unused [9:31]
_unused9: u7 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Flag Register, UARTFR
pub const UARTFR = Register(UARTFR_val).init(base_address + 0x18);

/// UARTRSR
const UARTRSR_val = packed struct {
/// FE [0:0]
/// Framing error. When set to 1, it indicates that the received character did not have a valid stop bit (a valid stop bit is 1). This bit is cleared to 0 by a write to UARTECR. In FIFO mode, this error is associated with the character at the top of the FIFO.
FE: u1 = 0,
/// PE [1:1]
/// Parity error. When set to 1, it indicates that the parity of the received data character does not match the parity that the EPS and SPS bits in the Line Control Register, UARTLCR_H. This bit is cleared to 0 by a write to UARTECR. In FIFO mode, this error is associated with the character at the top of the FIFO.
PE: u1 = 0,
/// BE [2:2]
/// Break error. This bit is set to 1 if a break condition was detected, indicating that the received data input was held LOW for longer than a full-word transmission time (defined as start, data, parity, and stop bits). This bit is cleared to 0 after a write to UARTECR. In FIFO mode, this error is associated with the character at the top of the FIFO. When a break occurs, only one 0 character is loaded into the FIFO. The next character is only enabled after the receive data input goes to a 1 (marking state) and the next valid start bit is received.
BE: u1 = 0,
/// OE [3:3]
/// Overrun error. This bit is set to 1 if data is received and the FIFO is already full. This bit is cleared to 0 by a write to UARTECR. The FIFO contents remain valid because no more data is written when the FIFO is full, only the contents of the shift register are overwritten. The CPU must now read the data, to empty the FIFO.
OE: u1 = 0,
/// unused [4:31]
_unused4: u4 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Receive Status Register/Error Clear Register, UARTRSR/UARTECR
pub const UARTRSR = Register(UARTRSR_val).init(base_address + 0x4);

/// UARTDR
const UARTDR_val = packed struct {
/// DATA [0:7]
/// Receive (read) data character. Transmit (write) data character.
DATA: u8 = 0,
/// FE [8:8]
/// Framing error. When set to 1, it indicates that the received character did not have a valid stop bit (a valid stop bit is 1). In FIFO mode, this error is associated with the character at the top of the FIFO.
FE: u1 = 0,
/// PE [9:9]
/// Parity error. When set to 1, it indicates that the parity of the received data character does not match the parity that the EPS and SPS bits in the Line Control Register, UARTLCR_H. In FIFO mode, this error is associated with the character at the top of the FIFO.
PE: u1 = 0,
/// BE [10:10]
/// Break error. This bit is set to 1 if a break condition was detected, indicating that the received data input was held LOW for longer than a full-word transmission time (defined as start, data, parity and stop bits). In FIFO mode, this error is associated with the character at the top of the FIFO. When a break occurs, only one 0 character is loaded into the FIFO. The next character is only enabled after the receive data input goes to a 1 (marking state), and the next valid start bit is received.
BE: u1 = 0,
/// OE [11:11]
/// Overrun error. This bit is set to 1 if data is received and the receive FIFO is already full. This is cleared to 0 once there is an empty space in the FIFO and a new character can be written to it.
OE: u1 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Data Register, UARTDR
pub const UARTDR = Register(UARTDR_val).init(base_address + 0x0);
};

/// No description
pub const UART1 = struct {

const base_address = 0x40038000;
/// UARTPCELLID3
const UARTPCELLID3_val = packed struct {
/// UARTPCELLID3 [0:7]
/// These bits read back as 0xB1
UARTPCELLID3: u8 = 177,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// UARTPCellID3 Register
pub const UARTPCELLID3 = Register(UARTPCELLID3_val).init(base_address + 0xffc);

/// UARTPCELLID2
const UARTPCELLID2_val = packed struct {
/// UARTPCELLID2 [0:7]
/// These bits read back as 0x05
UARTPCELLID2: u8 = 5,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// UARTPCellID2 Register
pub const UARTPCELLID2 = Register(UARTPCELLID2_val).init(base_address + 0xff8);

/// UARTPCELLID1
const UARTPCELLID1_val = packed struct {
/// UARTPCELLID1 [0:7]
/// These bits read back as 0xF0
UARTPCELLID1: u8 = 240,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// UARTPCellID1 Register
pub const UARTPCELLID1 = Register(UARTPCELLID1_val).init(base_address + 0xff4);

/// UARTPCELLID0
const UARTPCELLID0_val = packed struct {
/// UARTPCELLID0 [0:7]
/// These bits read back as 0x0D
UARTPCELLID0: u8 = 13,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// UARTPCellID0 Register
pub const UARTPCELLID0 = Register(UARTPCELLID0_val).init(base_address + 0xff0);

/// UARTPERIPHID3
const UARTPERIPHID3_val = packed struct {
/// CONFIGURATION [0:7]
/// These bits read back as 0x00
CONFIGURATION: u8 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// UARTPeriphID3 Register
pub const UARTPERIPHID3 = Register(UARTPERIPHID3_val).init(base_address + 0xfec);

/// UARTPERIPHID2
const UARTPERIPHID2_val = packed struct {
/// DESIGNER1 [0:3]
/// These bits read back as 0x4
DESIGNER1: u4 = 4,
/// REVISION [4:7]
/// This field depends on the revision of the UART: r1p0 0x0 r1p1 0x1 r1p3 0x2 r1p4 0x2 r1p5 0x3
REVISION: u4 = 3,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// UARTPeriphID2 Register
pub const UARTPERIPHID2 = Register(UARTPERIPHID2_val).init(base_address + 0xfe8);

/// UARTPERIPHID1
const UARTPERIPHID1_val = packed struct {
/// PARTNUMBER1 [0:3]
/// These bits read back as 0x0
PARTNUMBER1: u4 = 0,
/// DESIGNER0 [4:7]
/// These bits read back as 0x1
DESIGNER0: u4 = 1,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// UARTPeriphID1 Register
pub const UARTPERIPHID1 = Register(UARTPERIPHID1_val).init(base_address + 0xfe4);

/// UARTPERIPHID0
const UARTPERIPHID0_val = packed struct {
/// PARTNUMBER0 [0:7]
/// These bits read back as 0x11
PARTNUMBER0: u8 = 17,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// UARTPeriphID0 Register
pub const UARTPERIPHID0 = Register(UARTPERIPHID0_val).init(base_address + 0xfe0);

/// UARTDMACR
const UARTDMACR_val = packed struct {
/// RXDMAE [0:0]
/// Receive DMA enable. If this bit is set to 1, DMA for the receive FIFO is enabled.
RXDMAE: u1 = 0,
/// TXDMAE [1:1]
/// Transmit DMA enable. If this bit is set to 1, DMA for the transmit FIFO is enabled.
TXDMAE: u1 = 0,
/// DMAONERR [2:2]
/// DMA on error. If this bit is set to 1, the DMA receive request outputs, UARTRXDMASREQ or UARTRXDMABREQ, are disabled when the UART error interrupt is asserted.
DMAONERR: u1 = 0,
/// unused [3:31]
_unused3: u5 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// DMA Control Register, UARTDMACR
pub const UARTDMACR = Register(UARTDMACR_val).init(base_address + 0x48);

/// UARTICR
const UARTICR_val = packed struct {
/// RIMIC [0:0]
/// nUARTRI modem interrupt clear. Clears the UARTRIINTR interrupt.
RIMIC: u1 = 0,
/// CTSMIC [1:1]
/// nUARTCTS modem interrupt clear. Clears the UARTCTSINTR interrupt.
CTSMIC: u1 = 0,
/// DCDMIC [2:2]
/// nUARTDCD modem interrupt clear. Clears the UARTDCDINTR interrupt.
DCDMIC: u1 = 0,
/// DSRMIC [3:3]
/// nUARTDSR modem interrupt clear. Clears the UARTDSRINTR interrupt.
DSRMIC: u1 = 0,
/// RXIC [4:4]
/// Receive interrupt clear. Clears the UARTRXINTR interrupt.
RXIC: u1 = 0,
/// TXIC [5:5]
/// Transmit interrupt clear. Clears the UARTTXINTR interrupt.
TXIC: u1 = 0,
/// RTIC [6:6]
/// Receive timeout interrupt clear. Clears the UARTRTINTR interrupt.
RTIC: u1 = 0,
/// FEIC [7:7]
/// Framing error interrupt clear. Clears the UARTFEINTR interrupt.
FEIC: u1 = 0,
/// PEIC [8:8]
/// Parity error interrupt clear. Clears the UARTPEINTR interrupt.
PEIC: u1 = 0,
/// BEIC [9:9]
/// Break error interrupt clear. Clears the UARTBEINTR interrupt.
BEIC: u1 = 0,
/// OEIC [10:10]
/// Overrun error interrupt clear. Clears the UARTOEINTR interrupt.
OEIC: u1 = 0,
/// unused [11:31]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Interrupt Clear Register, UARTICR
pub const UARTICR = Register(UARTICR_val).init(base_address + 0x44);

/// UARTMIS
const UARTMIS_val = packed struct {
/// RIMMIS [0:0]
/// nUARTRI modem masked interrupt status. Returns the masked interrupt state of the UARTRIINTR interrupt.
RIMMIS: u1 = 0,
/// CTSMMIS [1:1]
/// nUARTCTS modem masked interrupt status. Returns the masked interrupt state of the UARTCTSINTR interrupt.
CTSMMIS: u1 = 0,
/// DCDMMIS [2:2]
/// nUARTDCD modem masked interrupt status. Returns the masked interrupt state of the UARTDCDINTR interrupt.
DCDMMIS: u1 = 0,
/// DSRMMIS [3:3]
/// nUARTDSR modem masked interrupt status. Returns the masked interrupt state of the UARTDSRINTR interrupt.
DSRMMIS: u1 = 0,
/// RXMIS [4:4]
/// Receive masked interrupt status. Returns the masked interrupt state of the UARTRXINTR interrupt.
RXMIS: u1 = 0,
/// TXMIS [5:5]
/// Transmit masked interrupt status. Returns the masked interrupt state of the UARTTXINTR interrupt.
TXMIS: u1 = 0,
/// RTMIS [6:6]
/// Receive timeout masked interrupt status. Returns the masked interrupt state of the UARTRTINTR interrupt.
RTMIS: u1 = 0,
/// FEMIS [7:7]
/// Framing error masked interrupt status. Returns the masked interrupt state of the UARTFEINTR interrupt.
FEMIS: u1 = 0,
/// PEMIS [8:8]
/// Parity error masked interrupt status. Returns the masked interrupt state of the UARTPEINTR interrupt.
PEMIS: u1 = 0,
/// BEMIS [9:9]
/// Break error masked interrupt status. Returns the masked interrupt state of the UARTBEINTR interrupt.
BEMIS: u1 = 0,
/// OEMIS [10:10]
/// Overrun error masked interrupt status. Returns the masked interrupt state of the UARTOEINTR interrupt.
OEMIS: u1 = 0,
/// unused [11:31]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Masked Interrupt Status Register, UARTMIS
pub const UARTMIS = Register(UARTMIS_val).init(base_address + 0x40);

/// UARTRIS
const UARTRIS_val = packed struct {
/// RIRMIS [0:0]
/// nUARTRI modem interrupt status. Returns the raw interrupt state of the UARTRIINTR interrupt.
RIRMIS: u1 = 0,
/// CTSRMIS [1:1]
/// nUARTCTS modem interrupt status. Returns the raw interrupt state of the UARTCTSINTR interrupt.
CTSRMIS: u1 = 0,
/// DCDRMIS [2:2]
/// nUARTDCD modem interrupt status. Returns the raw interrupt state of the UARTDCDINTR interrupt.
DCDRMIS: u1 = 0,
/// DSRRMIS [3:3]
/// nUARTDSR modem interrupt status. Returns the raw interrupt state of the UARTDSRINTR interrupt.
DSRRMIS: u1 = 0,
/// RXRIS [4:4]
/// Receive interrupt status. Returns the raw interrupt state of the UARTRXINTR interrupt.
RXRIS: u1 = 0,
/// TXRIS [5:5]
/// Transmit interrupt status. Returns the raw interrupt state of the UARTTXINTR interrupt.
TXRIS: u1 = 0,
/// RTRIS [6:6]
/// Receive timeout interrupt status. Returns the raw interrupt state of the UARTRTINTR interrupt. a
RTRIS: u1 = 0,
/// FERIS [7:7]
/// Framing error interrupt status. Returns the raw interrupt state of the UARTFEINTR interrupt.
FERIS: u1 = 0,
/// PERIS [8:8]
/// Parity error interrupt status. Returns the raw interrupt state of the UARTPEINTR interrupt.
PERIS: u1 = 0,
/// BERIS [9:9]
/// Break error interrupt status. Returns the raw interrupt state of the UARTBEINTR interrupt.
BERIS: u1 = 0,
/// OERIS [10:10]
/// Overrun error interrupt status. Returns the raw interrupt state of the UARTOEINTR interrupt.
OERIS: u1 = 0,
/// unused [11:31]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Raw Interrupt Status Register, UARTRIS
pub const UARTRIS = Register(UARTRIS_val).init(base_address + 0x3c);

/// UARTIMSC
const UARTIMSC_val = packed struct {
/// RIMIM [0:0]
/// nUARTRI modem interrupt mask. A read returns the current mask for the UARTRIINTR interrupt. On a write of 1, the mask of the UARTRIINTR interrupt is set. A write of 0 clears the mask.
RIMIM: u1 = 0,
/// CTSMIM [1:1]
/// nUARTCTS modem interrupt mask. A read returns the current mask for the UARTCTSINTR interrupt. On a write of 1, the mask of the UARTCTSINTR interrupt is set. A write of 0 clears the mask.
CTSMIM: u1 = 0,
/// DCDMIM [2:2]
/// nUARTDCD modem interrupt mask. A read returns the current mask for the UARTDCDINTR interrupt. On a write of 1, the mask of the UARTDCDINTR interrupt is set. A write of 0 clears the mask.
DCDMIM: u1 = 0,
/// DSRMIM [3:3]
/// nUARTDSR modem interrupt mask. A read returns the current mask for the UARTDSRINTR interrupt. On a write of 1, the mask of the UARTDSRINTR interrupt is set. A write of 0 clears the mask.
DSRMIM: u1 = 0,
/// RXIM [4:4]
/// Receive interrupt mask. A read returns the current mask for the UARTRXINTR interrupt. On a write of 1, the mask of the UARTRXINTR interrupt is set. A write of 0 clears the mask.
RXIM: u1 = 0,
/// TXIM [5:5]
/// Transmit interrupt mask. A read returns the current mask for the UARTTXINTR interrupt. On a write of 1, the mask of the UARTTXINTR interrupt is set. A write of 0 clears the mask.
TXIM: u1 = 0,
/// RTIM [6:6]
/// Receive timeout interrupt mask. A read returns the current mask for the UARTRTINTR interrupt. On a write of 1, the mask of the UARTRTINTR interrupt is set. A write of 0 clears the mask.
RTIM: u1 = 0,
/// FEIM [7:7]
/// Framing error interrupt mask. A read returns the current mask for the UARTFEINTR interrupt. On a write of 1, the mask of the UARTFEINTR interrupt is set. A write of 0 clears the mask.
FEIM: u1 = 0,
/// PEIM [8:8]
/// Parity error interrupt mask. A read returns the current mask for the UARTPEINTR interrupt. On a write of 1, the mask of the UARTPEINTR interrupt is set. A write of 0 clears the mask.
PEIM: u1 = 0,
/// BEIM [9:9]
/// Break error interrupt mask. A read returns the current mask for the UARTBEINTR interrupt. On a write of 1, the mask of the UARTBEINTR interrupt is set. A write of 0 clears the mask.
BEIM: u1 = 0,
/// OEIM [10:10]
/// Overrun error interrupt mask. A read returns the current mask for the UARTOEINTR interrupt. On a write of 1, the mask of the UARTOEINTR interrupt is set. A write of 0 clears the mask.
OEIM: u1 = 0,
/// unused [11:31]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Interrupt Mask Set/Clear Register, UARTIMSC
pub const UARTIMSC = Register(UARTIMSC_val).init(base_address + 0x38);

/// UARTIFLS
const UARTIFLS_val = packed struct {
/// TXIFLSEL [0:2]
/// Transmit interrupt FIFO level select. The trigger points for the transmit interrupt are as follows: b000 = Transmit FIFO becomes &lt;= 1 / 8 full b001 = Transmit FIFO becomes &lt;= 1 / 4 full b010 = Transmit FIFO becomes &lt;= 1 / 2 full b011 = Transmit FIFO becomes &lt;= 3 / 4 full b100 = Transmit FIFO becomes &lt;= 7 / 8 full b101-b111 = reserved.
TXIFLSEL: u3 = 2,
/// RXIFLSEL [3:5]
/// Receive interrupt FIFO level select. The trigger points for the receive interrupt are as follows: b000 = Receive FIFO becomes &gt;= 1 / 8 full b001 = Receive FIFO becomes &gt;= 1 / 4 full b010 = Receive FIFO becomes &gt;= 1 / 2 full b011 = Receive FIFO becomes &gt;= 3 / 4 full b100 = Receive FIFO becomes &gt;= 7 / 8 full b101-b111 = reserved.
RXIFLSEL: u3 = 2,
/// unused [6:31]
_unused6: u2 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Interrupt FIFO Level Select Register, UARTIFLS
pub const UARTIFLS = Register(UARTIFLS_val).init(base_address + 0x34);

/// UARTCR
const UARTCR_val = packed struct {
/// UARTEN [0:0]
/// UART enable: 0 = UART is disabled. If the UART is disabled in the middle of transmission or reception, it completes the current character before stopping. 1 = the UART is enabled. Data transmission and reception occurs for either UART signals or SIR signals depending on the setting of the SIREN bit.
UARTEN: u1 = 0,
/// SIREN [1:1]
/// SIR enable: 0 = IrDA SIR ENDEC is disabled. nSIROUT remains LOW (no light pulse generated), and signal transitions on SIRIN have no effect. 1 = IrDA SIR ENDEC is enabled. Data is transmitted and received on nSIROUT and SIRIN. UARTTXD remains HIGH, in the marking state. Signal transitions on UARTRXD or modem status inputs have no effect. This bit has no effect if the UARTEN bit disables the UART.
SIREN: u1 = 0,
/// SIRLP [2:2]
/// SIR low-power IrDA mode. This bit selects the IrDA encoding mode. If this bit is cleared to 0, low-level bits are transmitted as an active high pulse with a width of 3 / 16th of the bit period. If this bit is set to 1, low-level bits are transmitted with a pulse width that is 3 times the period of the IrLPBaud16 input signal, regardless of the selected bit rate. Setting this bit uses less power, but might reduce transmission distances.
SIRLP: u1 = 0,
/// unused [3:6]
_unused3: u4 = 0,
/// LBE [7:7]
/// Loopback enable. If this bit is set to 1 and the SIREN bit is set to 1 and the SIRTEST bit in the Test Control Register, UARTTCR is set to 1, then the nSIROUT path is inverted, and fed through to the SIRIN path. The SIRTEST bit in the test register must be set to 1 to override the normal half-duplex SIR operation. This must be the requirement for accessing the test registers during normal operation, and SIRTEST must be cleared to 0 when loopback testing is finished. This feature reduces the amount of external coupling required during system test. If this bit is set to 1, and the SIRTEST bit is set to 0, the UARTTXD path is fed through to the UARTRXD path. In either SIR mode or UART mode, when this bit is set, the modem outputs are also fed through to the modem inputs. This bit is cleared to 0 on reset, to disable loopback.
LBE: u1 = 0,
/// TXE [8:8]
/// Transmit enable. If this bit is set to 1, the transmit section of the UART is enabled. Data transmission occurs for either UART signals, or SIR signals depending on the setting of the SIREN bit. When the UART is disabled in the middle of transmission, it completes the current character before stopping.
TXE: u1 = 1,
/// RXE [9:9]
/// Receive enable. If this bit is set to 1, the receive section of the UART is enabled. Data reception occurs for either UART signals or SIR signals depending on the setting of the SIREN bit. When the UART is disabled in the middle of reception, it completes the current character before stopping.
RXE: u1 = 1,
/// DTR [10:10]
/// Data transmit ready. This bit is the complement of the UART data transmit ready, nUARTDTR, modem status output. That is, when the bit is programmed to a 1 then nUARTDTR is LOW.
DTR: u1 = 0,
/// RTS [11:11]
/// Request to send. This bit is the complement of the UART request to send, nUARTRTS, modem status output. That is, when the bit is programmed to a 1 then nUARTRTS is LOW.
RTS: u1 = 0,
/// OUT1 [12:12]
/// This bit is the complement of the UART Out1 (nUARTOut1) modem status output. That is, when the bit is programmed to a 1 the output is 0. For DTE this can be used as Data Carrier Detect (DCD).
OUT1: u1 = 0,
/// OUT2 [13:13]
/// This bit is the complement of the UART Out2 (nUARTOut2) modem status output. That is, when the bit is programmed to a 1, the output is 0. For DTE this can be used as Ring Indicator (RI).
OUT2: u1 = 0,
/// RTSEN [14:14]
/// RTS hardware flow control enable. If this bit is set to 1, RTS hardware flow control is enabled. Data is only requested when there is space in the receive FIFO for it to be received.
RTSEN: u1 = 0,
/// CTSEN [15:15]
/// CTS hardware flow control enable. If this bit is set to 1, CTS hardware flow control is enabled. Data is only transmitted when the nUARTCTS signal is asserted.
CTSEN: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Control Register, UARTCR
pub const UARTCR = Register(UARTCR_val).init(base_address + 0x30);

/// UARTLCR_H
const UARTLCR_H_val = packed struct {
/// BRK [0:0]
/// Send break. If this bit is set to 1, a low-level is continually output on the UARTTXD output, after completing transmission of the current character. For the proper execution of the break command, the software must set this bit for at least two complete frames. For normal use, this bit must be cleared to 0.
BRK: u1 = 0,
/// PEN [1:1]
/// Parity enable: 0 = parity is disabled and no parity bit added to the data frame 1 = parity checking and generation is enabled.
PEN: u1 = 0,
/// EPS [2:2]
/// Even parity select. Controls the type of parity the UART uses during transmission and reception: 0 = odd parity. The UART generates or checks for an odd number of 1s in the data and parity bits. 1 = even parity. The UART generates or checks for an even number of 1s in the data and parity bits. This bit has no effect when the PEN bit disables parity checking and generation.
EPS: u1 = 0,
/// STP2 [3:3]
/// Two stop bits select. If this bit is set to 1, two stop bits are transmitted at the end of the frame. The receive logic does not check for two stop bits being received.
STP2: u1 = 0,
/// FEN [4:4]
/// Enable FIFOs: 0 = FIFOs are disabled (character mode) that is, the FIFOs become 1-byte-deep holding registers 1 = transmit and receive FIFO buffers are enabled (FIFO mode).
FEN: u1 = 0,
/// WLEN [5:6]
/// Word length. These bits indicate the number of data bits transmitted or received in a frame as follows: b11 = 8 bits b10 = 7 bits b01 = 6 bits b00 = 5 bits.
WLEN: u2 = 0,
/// SPS [7:7]
/// Stick parity select. 0 = stick parity is disabled 1 = either: * if the EPS bit is 0 then the parity bit is transmitted and checked as a 1 * if the EPS bit is 1 then the parity bit is transmitted and checked as a 0. This bit has no effect when the PEN bit disables parity checking and generation.
SPS: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Line Control Register, UARTLCR_H
pub const UARTLCR_H = Register(UARTLCR_H_val).init(base_address + 0x2c);

/// UARTFBRD
const UARTFBRD_val = packed struct {
/// BAUD_DIVFRAC [0:5]
/// The fractional baud rate divisor. These bits are cleared to 0 on reset.
BAUD_DIVFRAC: u6 = 0,
/// unused [6:31]
_unused6: u2 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Fractional Baud Rate Register, UARTFBRD
pub const UARTFBRD = Register(UARTFBRD_val).init(base_address + 0x28);

/// UARTIBRD
const UARTIBRD_val = packed struct {
/// BAUD_DIVINT [0:15]
/// The integer baud rate divisor. These bits are cleared to 0 on reset.
BAUD_DIVINT: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Integer Baud Rate Register, UARTIBRD
pub const UARTIBRD = Register(UARTIBRD_val).init(base_address + 0x24);

/// UARTILPR
const UARTILPR_val = packed struct {
/// ILPDVSR [0:7]
/// 8-bit low-power divisor value. These bits are cleared to 0 at reset.
ILPDVSR: u8 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// IrDA Low-Power Counter Register, UARTILPR
pub const UARTILPR = Register(UARTILPR_val).init(base_address + 0x20);

/// UARTFR
const UARTFR_val = packed struct {
/// CTS [0:0]
/// Clear to send. This bit is the complement of the UART clear to send, nUARTCTS, modem status input. That is, the bit is 1 when nUARTCTS is LOW.
CTS: u1 = 0,
/// DSR [1:1]
/// Data set ready. This bit is the complement of the UART data set ready, nUARTDSR, modem status input. That is, the bit is 1 when nUARTDSR is LOW.
DSR: u1 = 0,
/// DCD [2:2]
/// Data carrier detect. This bit is the complement of the UART data carrier detect, nUARTDCD, modem status input. That is, the bit is 1 when nUARTDCD is LOW.
DCD: u1 = 0,
/// BUSY [3:3]
/// UART busy. If this bit is set to 1, the UART is busy transmitting data. This bit remains set until the complete byte, including all the stop bits, has been sent from the shift register. This bit is set as soon as the transmit FIFO becomes non-empty, regardless of whether the UART is enabled or not.
BUSY: u1 = 0,
/// RXFE [4:4]
/// Receive FIFO empty. The meaning of this bit depends on the state of the FEN bit in the UARTLCR_H Register. If the FIFO is disabled, this bit is set when the receive holding register is empty. If the FIFO is enabled, the RXFE bit is set when the receive FIFO is empty.
RXFE: u1 = 1,
/// TXFF [5:5]
/// Transmit FIFO full. The meaning of this bit depends on the state of the FEN bit in the UARTLCR_H Register. If the FIFO is disabled, this bit is set when the transmit holding register is full. If the FIFO is enabled, the TXFF bit is set when the transmit FIFO is full.
TXFF: u1 = 0,
/// RXFF [6:6]
/// Receive FIFO full. The meaning of this bit depends on the state of the FEN bit in the UARTLCR_H Register. If the FIFO is disabled, this bit is set when the receive holding register is full. If the FIFO is enabled, the RXFF bit is set when the receive FIFO is full.
RXFF: u1 = 0,
/// TXFE [7:7]
/// Transmit FIFO empty. The meaning of this bit depends on the state of the FEN bit in the Line Control Register, UARTLCR_H. If the FIFO is disabled, this bit is set when the transmit holding register is empty. If the FIFO is enabled, the TXFE bit is set when the transmit FIFO is empty. This bit does not indicate if there is data in the transmit shift register.
TXFE: u1 = 1,
/// RI [8:8]
/// Ring indicator. This bit is the complement of the UART ring indicator, nUARTRI, modem status input. That is, the bit is 1 when nUARTRI is LOW.
RI: u1 = 0,
/// unused [9:31]
_unused9: u7 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Flag Register, UARTFR
pub const UARTFR = Register(UARTFR_val).init(base_address + 0x18);

/// UARTRSR
const UARTRSR_val = packed struct {
/// FE [0:0]
/// Framing error. When set to 1, it indicates that the received character did not have a valid stop bit (a valid stop bit is 1). This bit is cleared to 0 by a write to UARTECR. In FIFO mode, this error is associated with the character at the top of the FIFO.
FE: u1 = 0,
/// PE [1:1]
/// Parity error. When set to 1, it indicates that the parity of the received data character does not match the parity that the EPS and SPS bits in the Line Control Register, UARTLCR_H. This bit is cleared to 0 by a write to UARTECR. In FIFO mode, this error is associated with the character at the top of the FIFO.
PE: u1 = 0,
/// BE [2:2]
/// Break error. This bit is set to 1 if a break condition was detected, indicating that the received data input was held LOW for longer than a full-word transmission time (defined as start, data, parity, and stop bits). This bit is cleared to 0 after a write to UARTECR. In FIFO mode, this error is associated with the character at the top of the FIFO. When a break occurs, only one 0 character is loaded into the FIFO. The next character is only enabled after the receive data input goes to a 1 (marking state) and the next valid start bit is received.
BE: u1 = 0,
/// OE [3:3]
/// Overrun error. This bit is set to 1 if data is received and the FIFO is already full. This bit is cleared to 0 by a write to UARTECR. The FIFO contents remain valid because no more data is written when the FIFO is full, only the contents of the shift register are overwritten. The CPU must now read the data, to empty the FIFO.
OE: u1 = 0,
/// unused [4:31]
_unused4: u4 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Receive Status Register/Error Clear Register, UARTRSR/UARTECR
pub const UARTRSR = Register(UARTRSR_val).init(base_address + 0x4);

/// UARTDR
const UARTDR_val = packed struct {
/// DATA [0:7]
/// Receive (read) data character. Transmit (write) data character.
DATA: u8 = 0,
/// FE [8:8]
/// Framing error. When set to 1, it indicates that the received character did not have a valid stop bit (a valid stop bit is 1). In FIFO mode, this error is associated with the character at the top of the FIFO.
FE: u1 = 0,
/// PE [9:9]
/// Parity error. When set to 1, it indicates that the parity of the received data character does not match the parity that the EPS and SPS bits in the Line Control Register, UARTLCR_H. In FIFO mode, this error is associated with the character at the top of the FIFO.
PE: u1 = 0,
/// BE [10:10]
/// Break error. This bit is set to 1 if a break condition was detected, indicating that the received data input was held LOW for longer than a full-word transmission time (defined as start, data, parity and stop bits). In FIFO mode, this error is associated with the character at the top of the FIFO. When a break occurs, only one 0 character is loaded into the FIFO. The next character is only enabled after the receive data input goes to a 1 (marking state), and the next valid start bit is received.
BE: u1 = 0,
/// OE [11:11]
/// Overrun error. This bit is set to 1 if data is received and the receive FIFO is already full. This is cleared to 0 once there is an empty space in the FIFO and a new character can be written to it.
OE: u1 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Data Register, UARTDR
pub const UARTDR = Register(UARTDR_val).init(base_address + 0x0);
};

/// No description
pub const SPI0 = struct {

const base_address = 0x4003c000;
/// SSPPCELLID3
const SSPPCELLID3_val = packed struct {
/// SSPPCELLID3 [0:7]
/// These bits read back as 0xB1
SSPPCELLID3: u8 = 177,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// PrimeCell identification registers, SSPPCellID0-3 on page 3-16
pub const SSPPCELLID3 = Register(SSPPCELLID3_val).init(base_address + 0xffc);

/// SSPPCELLID2
const SSPPCELLID2_val = packed struct {
/// SSPPCELLID2 [0:7]
/// These bits read back as 0x05
SSPPCELLID2: u8 = 5,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// PrimeCell identification registers, SSPPCellID0-3 on page 3-16
pub const SSPPCELLID2 = Register(SSPPCELLID2_val).init(base_address + 0xff8);

/// SSPPCELLID1
const SSPPCELLID1_val = packed struct {
/// SSPPCELLID1 [0:7]
/// These bits read back as 0xF0
SSPPCELLID1: u8 = 240,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// PrimeCell identification registers, SSPPCellID0-3 on page 3-16
pub const SSPPCELLID1 = Register(SSPPCELLID1_val).init(base_address + 0xff4);

/// SSPPCELLID0
const SSPPCELLID0_val = packed struct {
/// SSPPCELLID0 [0:7]
/// These bits read back as 0x0D
SSPPCELLID0: u8 = 13,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// PrimeCell identification registers, SSPPCellID0-3 on page 3-16
pub const SSPPCELLID0 = Register(SSPPCELLID0_val).init(base_address + 0xff0);

/// SSPPERIPHID3
const SSPPERIPHID3_val = packed struct {
/// CONFIGURATION [0:7]
/// These bits read back as 0x00
CONFIGURATION: u8 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Peripheral identification registers, SSPPeriphID0-3 on page 3-13
pub const SSPPERIPHID3 = Register(SSPPERIPHID3_val).init(base_address + 0xfec);

/// SSPPERIPHID2
const SSPPERIPHID2_val = packed struct {
/// DESIGNER1 [0:3]
/// These bits read back as 0x4
DESIGNER1: u4 = 4,
/// REVISION [4:7]
/// These bits return the peripheral revision
REVISION: u4 = 3,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Peripheral identification registers, SSPPeriphID0-3 on page 3-13
pub const SSPPERIPHID2 = Register(SSPPERIPHID2_val).init(base_address + 0xfe8);

/// SSPPERIPHID1
const SSPPERIPHID1_val = packed struct {
/// PARTNUMBER1 [0:3]
/// These bits read back as 0x0
PARTNUMBER1: u4 = 0,
/// DESIGNER0 [4:7]
/// These bits read back as 0x1
DESIGNER0: u4 = 1,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Peripheral identification registers, SSPPeriphID0-3 on page 3-13
pub const SSPPERIPHID1 = Register(SSPPERIPHID1_val).init(base_address + 0xfe4);

/// SSPPERIPHID0
const SSPPERIPHID0_val = packed struct {
/// PARTNUMBER0 [0:7]
/// These bits read back as 0x22
PARTNUMBER0: u8 = 34,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Peripheral identification registers, SSPPeriphID0-3 on page 3-13
pub const SSPPERIPHID0 = Register(SSPPERIPHID0_val).init(base_address + 0xfe0);

/// SSPDMACR
const SSPDMACR_val = packed struct {
/// RXDMAE [0:0]
/// Receive DMA Enable. If this bit is set to 1, DMA for the receive FIFO is enabled.
RXDMAE: u1 = 0,
/// TXDMAE [1:1]
/// Transmit DMA Enable. If this bit is set to 1, DMA for the transmit FIFO is enabled.
TXDMAE: u1 = 0,
/// unused [2:31]
_unused2: u6 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// DMA control register, SSPDMACR on page 3-12
pub const SSPDMACR = Register(SSPDMACR_val).init(base_address + 0x24);

/// SSPICR
const SSPICR_val = packed struct {
/// RORIC [0:0]
/// Clears the SSPRORINTR interrupt
RORIC: u1 = 0,
/// RTIC [1:1]
/// Clears the SSPRTINTR interrupt
RTIC: u1 = 0,
/// unused [2:31]
_unused2: u6 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Interrupt clear register, SSPICR on page 3-11
pub const SSPICR = Register(SSPICR_val).init(base_address + 0x20);

/// SSPMIS
const SSPMIS_val = packed struct {
/// RORMIS [0:0]
/// Gives the receive over run masked interrupt status, after masking, of the SSPRORINTR interrupt
RORMIS: u1 = 0,
/// RTMIS [1:1]
/// Gives the receive timeout masked interrupt state, after masking, of the SSPRTINTR interrupt
RTMIS: u1 = 0,
/// RXMIS [2:2]
/// Gives the receive FIFO masked interrupt state, after masking, of the SSPRXINTR interrupt
RXMIS: u1 = 0,
/// TXMIS [3:3]
/// Gives the transmit FIFO masked interrupt state, after masking, of the SSPTXINTR interrupt
TXMIS: u1 = 0,
/// unused [4:31]
_unused4: u4 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Masked interrupt status register, SSPMIS on page 3-11
pub const SSPMIS = Register(SSPMIS_val).init(base_address + 0x1c);

/// SSPRIS
const SSPRIS_val = packed struct {
/// RORRIS [0:0]
/// Gives the raw interrupt state, prior to masking, of the SSPRORINTR interrupt
RORRIS: u1 = 0,
/// RTRIS [1:1]
/// Gives the raw interrupt state, prior to masking, of the SSPRTINTR interrupt
RTRIS: u1 = 0,
/// RXRIS [2:2]
/// Gives the raw interrupt state, prior to masking, of the SSPRXINTR interrupt
RXRIS: u1 = 0,
/// TXRIS [3:3]
/// Gives the raw interrupt state, prior to masking, of the SSPTXINTR interrupt
TXRIS: u1 = 1,
/// unused [4:31]
_unused4: u4 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Raw interrupt status register, SSPRIS on page 3-10
pub const SSPRIS = Register(SSPRIS_val).init(base_address + 0x18);

/// SSPIMSC
const SSPIMSC_val = packed struct {
/// RORIM [0:0]
/// Receive overrun interrupt mask: 0 Receive FIFO written to while full condition interrupt is masked. 1 Receive FIFO written to while full condition interrupt is not masked.
RORIM: u1 = 0,
/// RTIM [1:1]
/// Receive timeout interrupt mask: 0 Receive FIFO not empty and no read prior to timeout period interrupt is masked. 1 Receive FIFO not empty and no read prior to timeout period interrupt is not masked.
RTIM: u1 = 0,
/// RXIM [2:2]
/// Receive FIFO interrupt mask: 0 Receive FIFO half full or less condition interrupt is masked. 1 Receive FIFO half full or less condition interrupt is not masked.
RXIM: u1 = 0,
/// TXIM [3:3]
/// Transmit FIFO interrupt mask: 0 Transmit FIFO half empty or less condition interrupt is masked. 1 Transmit FIFO half empty or less condition interrupt is not masked.
TXIM: u1 = 0,
/// unused [4:31]
_unused4: u4 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Interrupt mask set or clear register, SSPIMSC on page 3-9
pub const SSPIMSC = Register(SSPIMSC_val).init(base_address + 0x14);

/// SSPCPSR
const SSPCPSR_val = packed struct {
/// CPSDVSR [0:7]
/// Clock prescale divisor. Must be an even number from 2-254, depending on the frequency of SSPCLK. The least significant bit always returns zero on reads.
CPSDVSR: u8 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Clock prescale register, SSPCPSR on page 3-8
pub const SSPCPSR = Register(SSPCPSR_val).init(base_address + 0x10);

/// SSPSR
const SSPSR_val = packed struct {
/// TFE [0:0]
/// Transmit FIFO empty, RO: 0 Transmit FIFO is not empty. 1 Transmit FIFO is empty.
TFE: u1 = 1,
/// TNF [1:1]
/// Transmit FIFO not full, RO: 0 Transmit FIFO is full. 1 Transmit FIFO is not full.
TNF: u1 = 1,
/// RNE [2:2]
/// Receive FIFO not empty, RO: 0 Receive FIFO is empty. 1 Receive FIFO is not empty.
RNE: u1 = 0,
/// RFF [3:3]
/// Receive FIFO full, RO: 0 Receive FIFO is not full. 1 Receive FIFO is full.
RFF: u1 = 0,
/// BSY [4:4]
/// PrimeCell SSP busy flag, RO: 0 SSP is idle. 1 SSP is currently transmitting and/or receiving a frame or the transmit FIFO is not empty.
BSY: u1 = 0,
/// unused [5:31]
_unused5: u3 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Status register, SSPSR on page 3-7
pub const SSPSR = Register(SSPSR_val).init(base_address + 0xc);

/// SSPDR
const SSPDR_val = packed struct {
/// DATA [0:15]
/// Transmit/Receive FIFO: Read Receive FIFO. Write Transmit FIFO. You must right-justify data when the PrimeCell SSP is programmed for a data size that is less than 16 bits. Unused bits at the top are ignored by transmit logic. The receive logic automatically right-justifies.
DATA: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Data register, SSPDR on page 3-6
pub const SSPDR = Register(SSPDR_val).init(base_address + 0x8);

/// SSPCR1
const SSPCR1_val = packed struct {
/// LBM [0:0]
/// Loop back mode: 0 Normal serial port operation enabled. 1 Output of transmit serial shifter is connected to input of receive serial shifter internally.
LBM: u1 = 0,
/// SSE [1:1]
/// Synchronous serial port enable: 0 SSP operation disabled. 1 SSP operation enabled.
SSE: u1 = 0,
/// MS [2:2]
/// Master or slave mode select. This bit can be modified only when the PrimeCell SSP is disabled, SSE=0: 0 Device configured as master, default. 1 Device configured as slave.
MS: u1 = 0,
/// SOD [3:3]
/// Slave-mode output disable. This bit is relevant only in the slave mode, MS=1. In multiple-slave systems, it is possible for an PrimeCell SSP master to broadcast a message to all slaves in the system while ensuring that only one slave drives data onto its serial output line. In such systems the RXD lines from multiple slaves could be tied together. To operate in such systems, the SOD bit can be set if the PrimeCell SSP slave is not supposed to drive the SSPTXD line: 0 SSP can drive the SSPTXD output in slave mode. 1 SSP must not drive the SSPTXD output in slave mode.
SOD: u1 = 0,
/// unused [4:31]
_unused4: u4 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Control register 1, SSPCR1 on page 3-5
pub const SSPCR1 = Register(SSPCR1_val).init(base_address + 0x4);

/// SSPCR0
const SSPCR0_val = packed struct {
/// DSS [0:3]
/// Data Size Select: 0000 Reserved, undefined operation. 0001 Reserved, undefined operation. 0010 Reserved, undefined operation. 0011 4-bit data. 0100 5-bit data. 0101 6-bit data. 0110 7-bit data. 0111 8-bit data. 1000 9-bit data. 1001 10-bit data. 1010 11-bit data. 1011 12-bit data. 1100 13-bit data. 1101 14-bit data. 1110 15-bit data. 1111 16-bit data.
DSS: u4 = 0,
/// FRF [4:5]
/// Frame format: 00 Motorola SPI frame format. 01 TI synchronous serial frame format. 10 National Microwire frame format. 11 Reserved, undefined operation.
FRF: u2 = 0,
/// SPO [6:6]
/// SSPCLKOUT polarity, applicable to Motorola SPI frame format only. See Motorola SPI frame format on page 2-10.
SPO: u1 = 0,
/// SPH [7:7]
/// SSPCLKOUT phase, applicable to Motorola SPI frame format only. See Motorola SPI frame format on page 2-10.
SPH: u1 = 0,
/// SCR [8:15]
/// Serial clock rate. The value SCR is used to generate the transmit and receive bit rate of the PrimeCell SSP. The bit rate is: F SSPCLK CPSDVSR x (1+SCR) where CPSDVSR is an even value from 2-254, programmed through the SSPCPSR register and SCR is a value from 0-255.
SCR: u8 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Control register 0, SSPCR0 on page 3-4
pub const SSPCR0 = Register(SSPCR0_val).init(base_address + 0x0);
};

/// No description
pub const SPI1 = struct {

const base_address = 0x40040000;
/// SSPPCELLID3
const SSPPCELLID3_val = packed struct {
/// SSPPCELLID3 [0:7]
/// These bits read back as 0xB1
SSPPCELLID3: u8 = 177,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// PrimeCell identification registers, SSPPCellID0-3 on page 3-16
pub const SSPPCELLID3 = Register(SSPPCELLID3_val).init(base_address + 0xffc);

/// SSPPCELLID2
const SSPPCELLID2_val = packed struct {
/// SSPPCELLID2 [0:7]
/// These bits read back as 0x05
SSPPCELLID2: u8 = 5,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// PrimeCell identification registers, SSPPCellID0-3 on page 3-16
pub const SSPPCELLID2 = Register(SSPPCELLID2_val).init(base_address + 0xff8);

/// SSPPCELLID1
const SSPPCELLID1_val = packed struct {
/// SSPPCELLID1 [0:7]
/// These bits read back as 0xF0
SSPPCELLID1: u8 = 240,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// PrimeCell identification registers, SSPPCellID0-3 on page 3-16
pub const SSPPCELLID1 = Register(SSPPCELLID1_val).init(base_address + 0xff4);

/// SSPPCELLID0
const SSPPCELLID0_val = packed struct {
/// SSPPCELLID0 [0:7]
/// These bits read back as 0x0D
SSPPCELLID0: u8 = 13,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// PrimeCell identification registers, SSPPCellID0-3 on page 3-16
pub const SSPPCELLID0 = Register(SSPPCELLID0_val).init(base_address + 0xff0);

/// SSPPERIPHID3
const SSPPERIPHID3_val = packed struct {
/// CONFIGURATION [0:7]
/// These bits read back as 0x00
CONFIGURATION: u8 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Peripheral identification registers, SSPPeriphID0-3 on page 3-13
pub const SSPPERIPHID3 = Register(SSPPERIPHID3_val).init(base_address + 0xfec);

/// SSPPERIPHID2
const SSPPERIPHID2_val = packed struct {
/// DESIGNER1 [0:3]
/// These bits read back as 0x4
DESIGNER1: u4 = 4,
/// REVISION [4:7]
/// These bits return the peripheral revision
REVISION: u4 = 3,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Peripheral identification registers, SSPPeriphID0-3 on page 3-13
pub const SSPPERIPHID2 = Register(SSPPERIPHID2_val).init(base_address + 0xfe8);

/// SSPPERIPHID1
const SSPPERIPHID1_val = packed struct {
/// PARTNUMBER1 [0:3]
/// These bits read back as 0x0
PARTNUMBER1: u4 = 0,
/// DESIGNER0 [4:7]
/// These bits read back as 0x1
DESIGNER0: u4 = 1,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Peripheral identification registers, SSPPeriphID0-3 on page 3-13
pub const SSPPERIPHID1 = Register(SSPPERIPHID1_val).init(base_address + 0xfe4);

/// SSPPERIPHID0
const SSPPERIPHID0_val = packed struct {
/// PARTNUMBER0 [0:7]
/// These bits read back as 0x22
PARTNUMBER0: u8 = 34,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Peripheral identification registers, SSPPeriphID0-3 on page 3-13
pub const SSPPERIPHID0 = Register(SSPPERIPHID0_val).init(base_address + 0xfe0);

/// SSPDMACR
const SSPDMACR_val = packed struct {
/// RXDMAE [0:0]
/// Receive DMA Enable. If this bit is set to 1, DMA for the receive FIFO is enabled.
RXDMAE: u1 = 0,
/// TXDMAE [1:1]
/// Transmit DMA Enable. If this bit is set to 1, DMA for the transmit FIFO is enabled.
TXDMAE: u1 = 0,
/// unused [2:31]
_unused2: u6 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// DMA control register, SSPDMACR on page 3-12
pub const SSPDMACR = Register(SSPDMACR_val).init(base_address + 0x24);

/// SSPICR
const SSPICR_val = packed struct {
/// RORIC [0:0]
/// Clears the SSPRORINTR interrupt
RORIC: u1 = 0,
/// RTIC [1:1]
/// Clears the SSPRTINTR interrupt
RTIC: u1 = 0,
/// unused [2:31]
_unused2: u6 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Interrupt clear register, SSPICR on page 3-11
pub const SSPICR = Register(SSPICR_val).init(base_address + 0x20);

/// SSPMIS
const SSPMIS_val = packed struct {
/// RORMIS [0:0]
/// Gives the receive over run masked interrupt status, after masking, of the SSPRORINTR interrupt
RORMIS: u1 = 0,
/// RTMIS [1:1]
/// Gives the receive timeout masked interrupt state, after masking, of the SSPRTINTR interrupt
RTMIS: u1 = 0,
/// RXMIS [2:2]
/// Gives the receive FIFO masked interrupt state, after masking, of the SSPRXINTR interrupt
RXMIS: u1 = 0,
/// TXMIS [3:3]
/// Gives the transmit FIFO masked interrupt state, after masking, of the SSPTXINTR interrupt
TXMIS: u1 = 0,
/// unused [4:31]
_unused4: u4 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Masked interrupt status register, SSPMIS on page 3-11
pub const SSPMIS = Register(SSPMIS_val).init(base_address + 0x1c);

/// SSPRIS
const SSPRIS_val = packed struct {
/// RORRIS [0:0]
/// Gives the raw interrupt state, prior to masking, of the SSPRORINTR interrupt
RORRIS: u1 = 0,
/// RTRIS [1:1]
/// Gives the raw interrupt state, prior to masking, of the SSPRTINTR interrupt
RTRIS: u1 = 0,
/// RXRIS [2:2]
/// Gives the raw interrupt state, prior to masking, of the SSPRXINTR interrupt
RXRIS: u1 = 0,
/// TXRIS [3:3]
/// Gives the raw interrupt state, prior to masking, of the SSPTXINTR interrupt
TXRIS: u1 = 1,
/// unused [4:31]
_unused4: u4 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Raw interrupt status register, SSPRIS on page 3-10
pub const SSPRIS = Register(SSPRIS_val).init(base_address + 0x18);

/// SSPIMSC
const SSPIMSC_val = packed struct {
/// RORIM [0:0]
/// Receive overrun interrupt mask: 0 Receive FIFO written to while full condition interrupt is masked. 1 Receive FIFO written to while full condition interrupt is not masked.
RORIM: u1 = 0,
/// RTIM [1:1]
/// Receive timeout interrupt mask: 0 Receive FIFO not empty and no read prior to timeout period interrupt is masked. 1 Receive FIFO not empty and no read prior to timeout period interrupt is not masked.
RTIM: u1 = 0,
/// RXIM [2:2]
/// Receive FIFO interrupt mask: 0 Receive FIFO half full or less condition interrupt is masked. 1 Receive FIFO half full or less condition interrupt is not masked.
RXIM: u1 = 0,
/// TXIM [3:3]
/// Transmit FIFO interrupt mask: 0 Transmit FIFO half empty or less condition interrupt is masked. 1 Transmit FIFO half empty or less condition interrupt is not masked.
TXIM: u1 = 0,
/// unused [4:31]
_unused4: u4 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Interrupt mask set or clear register, SSPIMSC on page 3-9
pub const SSPIMSC = Register(SSPIMSC_val).init(base_address + 0x14);

/// SSPCPSR
const SSPCPSR_val = packed struct {
/// CPSDVSR [0:7]
/// Clock prescale divisor. Must be an even number from 2-254, depending on the frequency of SSPCLK. The least significant bit always returns zero on reads.
CPSDVSR: u8 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Clock prescale register, SSPCPSR on page 3-8
pub const SSPCPSR = Register(SSPCPSR_val).init(base_address + 0x10);

/// SSPSR
const SSPSR_val = packed struct {
/// TFE [0:0]
/// Transmit FIFO empty, RO: 0 Transmit FIFO is not empty. 1 Transmit FIFO is empty.
TFE: u1 = 1,
/// TNF [1:1]
/// Transmit FIFO not full, RO: 0 Transmit FIFO is full. 1 Transmit FIFO is not full.
TNF: u1 = 1,
/// RNE [2:2]
/// Receive FIFO not empty, RO: 0 Receive FIFO is empty. 1 Receive FIFO is not empty.
RNE: u1 = 0,
/// RFF [3:3]
/// Receive FIFO full, RO: 0 Receive FIFO is not full. 1 Receive FIFO is full.
RFF: u1 = 0,
/// BSY [4:4]
/// PrimeCell SSP busy flag, RO: 0 SSP is idle. 1 SSP is currently transmitting and/or receiving a frame or the transmit FIFO is not empty.
BSY: u1 = 0,
/// unused [5:31]
_unused5: u3 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Status register, SSPSR on page 3-7
pub const SSPSR = Register(SSPSR_val).init(base_address + 0xc);

/// SSPDR
const SSPDR_val = packed struct {
/// DATA [0:15]
/// Transmit/Receive FIFO: Read Receive FIFO. Write Transmit FIFO. You must right-justify data when the PrimeCell SSP is programmed for a data size that is less than 16 bits. Unused bits at the top are ignored by transmit logic. The receive logic automatically right-justifies.
DATA: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Data register, SSPDR on page 3-6
pub const SSPDR = Register(SSPDR_val).init(base_address + 0x8);

/// SSPCR1
const SSPCR1_val = packed struct {
/// LBM [0:0]
/// Loop back mode: 0 Normal serial port operation enabled. 1 Output of transmit serial shifter is connected to input of receive serial shifter internally.
LBM: u1 = 0,
/// SSE [1:1]
/// Synchronous serial port enable: 0 SSP operation disabled. 1 SSP operation enabled.
SSE: u1 = 0,
/// MS [2:2]
/// Master or slave mode select. This bit can be modified only when the PrimeCell SSP is disabled, SSE=0: 0 Device configured as master, default. 1 Device configured as slave.
MS: u1 = 0,
/// SOD [3:3]
/// Slave-mode output disable. This bit is relevant only in the slave mode, MS=1. In multiple-slave systems, it is possible for an PrimeCell SSP master to broadcast a message to all slaves in the system while ensuring that only one slave drives data onto its serial output line. In such systems the RXD lines from multiple slaves could be tied together. To operate in such systems, the SOD bit can be set if the PrimeCell SSP slave is not supposed to drive the SSPTXD line: 0 SSP can drive the SSPTXD output in slave mode. 1 SSP must not drive the SSPTXD output in slave mode.
SOD: u1 = 0,
/// unused [4:31]
_unused4: u4 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Control register 1, SSPCR1 on page 3-5
pub const SSPCR1 = Register(SSPCR1_val).init(base_address + 0x4);

/// SSPCR0
const SSPCR0_val = packed struct {
/// DSS [0:3]
/// Data Size Select: 0000 Reserved, undefined operation. 0001 Reserved, undefined operation. 0010 Reserved, undefined operation. 0011 4-bit data. 0100 5-bit data. 0101 6-bit data. 0110 7-bit data. 0111 8-bit data. 1000 9-bit data. 1001 10-bit data. 1010 11-bit data. 1011 12-bit data. 1100 13-bit data. 1101 14-bit data. 1110 15-bit data. 1111 16-bit data.
DSS: u4 = 0,
/// FRF [4:5]
/// Frame format: 00 Motorola SPI frame format. 01 TI synchronous serial frame format. 10 National Microwire frame format. 11 Reserved, undefined operation.
FRF: u2 = 0,
/// SPO [6:6]
/// SSPCLKOUT polarity, applicable to Motorola SPI frame format only. See Motorola SPI frame format on page 2-10.
SPO: u1 = 0,
/// SPH [7:7]
/// SSPCLKOUT phase, applicable to Motorola SPI frame format only. See Motorola SPI frame format on page 2-10.
SPH: u1 = 0,
/// SCR [8:15]
/// Serial clock rate. The value SCR is used to generate the transmit and receive bit rate of the PrimeCell SSP. The bit rate is: F SSPCLK CPSDVSR x (1+SCR) where CPSDVSR is an even value from 2-254, programmed through the SSPCPSR register and SCR is a value from 0-255.
SCR: u8 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Control register 0, SSPCR0 on page 3-4
pub const SSPCR0 = Register(SSPCR0_val).init(base_address + 0x0);
};

/// DW_apb_i2c address block
pub const I2C0 = struct {

const base_address = 0x40044000;
/// IC_COMP_TYPE
const IC_COMP_TYPE_val = packed struct {
/// IC_COMP_TYPE [0:31]
/// Designware Component Type number = 0x44_57_01_40. This assigned unique hex value is constant and is derived from the two ASCII letters 'DW' followed by a 16-bit unsigned number.
IC_COMP_TYPE: u32 = 1146552640,
};
/// I2C Component Type Register
pub const IC_COMP_TYPE = Register(IC_COMP_TYPE_val).init(base_address + 0xfc);

/// IC_COMP_VERSION
const IC_COMP_VERSION_val = packed struct {
/// IC_COMP_VERSION [0:31]
/// No description
IC_COMP_VERSION: u32 = 842019114,
};
/// I2C Component Version Register
pub const IC_COMP_VERSION = Register(IC_COMP_VERSION_val).init(base_address + 0xf8);

/// IC_COMP_PARAM_1
const IC_COMP_PARAM_1_val = packed struct {
/// APB_DATA_WIDTH [0:1]
/// APB data bus width is 32 bits
APB_DATA_WIDTH: u2 = 0,
/// MAX_SPEED_MODE [2:3]
/// MAX SPEED MODE = FAST MODE
MAX_SPEED_MODE: u2 = 0,
/// HC_COUNT_VALUES [4:4]
/// Programmable count values for each mode.
HC_COUNT_VALUES: u1 = 0,
/// INTR_IO [5:5]
/// COMBINED Interrupt outputs
INTR_IO: u1 = 0,
/// HAS_DMA [6:6]
/// DMA handshaking signals are enabled
HAS_DMA: u1 = 0,
/// ADD_ENCODED_PARAMS [7:7]
/// Encoded parameters not visible
ADD_ENCODED_PARAMS: u1 = 0,
/// RX_BUFFER_DEPTH [8:15]
/// RX Buffer Depth = 16
RX_BUFFER_DEPTH: u8 = 0,
/// TX_BUFFER_DEPTH [16:23]
/// TX Buffer Depth = 16
TX_BUFFER_DEPTH: u8 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// Component Parameter Register 1\n\n
pub const IC_COMP_PARAM_1 = Register(IC_COMP_PARAM_1_val).init(base_address + 0xf4);

/// IC_CLR_RESTART_DET
const IC_CLR_RESTART_DET_val = packed struct {
/// CLR_RESTART_DET [0:0]
/// Read this register to clear the RESTART_DET interrupt (bit 12) of IC_RAW_INTR_STAT register.\n\n
CLR_RESTART_DET: u1 = 0,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Clear RESTART_DET Interrupt Register
pub const IC_CLR_RESTART_DET = Register(IC_CLR_RESTART_DET_val).init(base_address + 0xa8);

/// IC_FS_SPKLEN
const IC_FS_SPKLEN_val = packed struct {
/// IC_FS_SPKLEN [0:7]
/// This register must be set before any I2C bus transaction can take place to ensure stable operation. This register sets the duration, measured in ic_clk cycles, of the longest spike in the SCL or SDA lines that will be filtered out by the spike suppression logic. This register can be written only when the I2C interface is disabled which corresponds to the IC_ENABLE[0] register being set to 0. Writes at other times have no effect. The minimum valid value is 1; hardware prevents values less than this being written, and if attempted results in 1 being set. or more information, refer to 'Spike Suppression'.
IC_FS_SPKLEN: u8 = 7,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// I2C SS, FS or FM+ spike suppression limit\n\n
pub const IC_FS_SPKLEN = Register(IC_FS_SPKLEN_val).init(base_address + 0xa0);

/// IC_ENABLE_STATUS
const IC_ENABLE_STATUS_val = packed struct {
/// IC_EN [0:0]
/// ic_en Status. This bit always reflects the value driven on the output port ic_en. - When read as 1, DW_apb_i2c is deemed to be in an enabled state. - When read as 0, DW_apb_i2c is deemed completely inactive. Note:  The CPU can safely read this bit anytime. When this bit is read as 0, the CPU can safely read SLV_RX_DATA_LOST (bit 2) and SLV_DISABLED_WHILE_BUSY (bit 1).\n\n
IC_EN: u1 = 0,
/// SLV_DISABLED_WHILE_BUSY [1:1]
/// Slave Disabled While Busy (Transmit, Receive). This bit indicates if a potential or active Slave operation has been aborted due to the setting bit 0 of the IC_ENABLE register from 1 to 0. This bit is set when the CPU writes a 0 to the IC_ENABLE register while:\n\n
SLV_DISABLED_WHILE_BUSY: u1 = 0,
/// SLV_RX_DATA_LOST [2:2]
/// Slave Received Data Lost. This bit indicates if a Slave-Receiver operation has been aborted with at least one data byte received from an I2C transfer due to the setting bit 0 of IC_ENABLE from 1 to 0. When read as 1, DW_apb_i2c is deemed to have been actively engaged in an aborted I2C transfer (with matching address) and the data phase of the I2C transfer has been entered, even though a data byte has been responded with a NACK.\n\n
SLV_RX_DATA_LOST: u1 = 0,
/// unused [3:31]
_unused3: u5 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// I2C Enable Status Register\n\n
pub const IC_ENABLE_STATUS = Register(IC_ENABLE_STATUS_val).init(base_address + 0x9c);

/// IC_ACK_GENERAL_CALL
const IC_ACK_GENERAL_CALL_val = packed struct {
/// ACK_GEN_CALL [0:0]
/// ACK General Call. When set to 1, DW_apb_i2c responds with a ACK (by asserting ic_data_oe) when it receives a General Call. Otherwise, DW_apb_i2c responds with a NACK (by negating ic_data_oe).
ACK_GEN_CALL: u1 = 1,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// I2C ACK General Call Register\n\n
pub const IC_ACK_GENERAL_CALL = Register(IC_ACK_GENERAL_CALL_val).init(base_address + 0x98);

/// IC_SDA_SETUP
const IC_SDA_SETUP_val = packed struct {
/// SDA_SETUP [0:7]
/// SDA Setup. It is recommended that if the required delay is 1000ns, then for an ic_clk frequency of 10 MHz, IC_SDA_SETUP should be programmed to a value of 11. IC_SDA_SETUP must be programmed with a minimum value of 2.
SDA_SETUP: u8 = 100,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// I2C SDA Setup Register\n\n
pub const IC_SDA_SETUP = Register(IC_SDA_SETUP_val).init(base_address + 0x94);

/// IC_DMA_RDLR
const IC_DMA_RDLR_val = packed struct {
/// DMARDL [0:3]
/// Receive Data Level. This bit field controls the level at which a DMA request is made by the receive logic. The watermark level = DMARDL+1; that is, dma_rx_req is generated when the number of valid data entries in the receive FIFO is equal to or more than this field value + 1, and RDMAE =1. For instance, when DMARDL is 0, then dma_rx_req is asserted when 1 or more data entries are present in the receive FIFO.\n\n
DMARDL: u4 = 0,
/// unused [4:31]
_unused4: u4 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// I2C Receive Data Level Register
pub const IC_DMA_RDLR = Register(IC_DMA_RDLR_val).init(base_address + 0x90);

/// IC_DMA_TDLR
const IC_DMA_TDLR_val = packed struct {
/// DMATDL [0:3]
/// Transmit Data Level. This bit field controls the level at which a DMA request is made by the transmit logic. It is equal to the watermark level; that is, the dma_tx_req signal is generated when the number of valid data entries in the transmit FIFO is equal to or below this field value, and TDMAE = 1.\n\n
DMATDL: u4 = 0,
/// unused [4:31]
_unused4: u4 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// DMA Transmit Data Level Register
pub const IC_DMA_TDLR = Register(IC_DMA_TDLR_val).init(base_address + 0x8c);

/// IC_DMA_CR
const IC_DMA_CR_val = packed struct {
/// RDMAE [0:0]
/// Receive DMA Enable. This bit enables/disables the receive FIFO DMA channel. Reset value: 0x0
RDMAE: u1 = 0,
/// TDMAE [1:1]
/// Transmit DMA Enable. This bit enables/disables the transmit FIFO DMA channel. Reset value: 0x0
TDMAE: u1 = 0,
/// unused [2:31]
_unused2: u6 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// DMA Control Register\n\n
pub const IC_DMA_CR = Register(IC_DMA_CR_val).init(base_address + 0x88);

/// IC_SLV_DATA_NACK_ONLY
const IC_SLV_DATA_NACK_ONLY_val = packed struct {
/// NACK [0:0]
/// Generate NACK. This NACK generation only occurs when DW_apb_i2c is a slave-receiver. If this register is set to a value of 1, it can only generate a NACK after a data byte is received; hence, the data transfer is aborted and the data received is not pushed to the receive buffer.\n\n
NACK: u1 = 0,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Generate Slave Data NACK Register\n\n
pub const IC_SLV_DATA_NACK_ONLY = Register(IC_SLV_DATA_NACK_ONLY_val).init(base_address + 0x84);

/// IC_TX_ABRT_SOURCE
const IC_TX_ABRT_SOURCE_val = packed struct {
/// ABRT_7B_ADDR_NOACK [0:0]
/// This field indicates that the Master is in 7-bit addressing mode and the address sent was not acknowledged by any slave.\n\n
ABRT_7B_ADDR_NOACK: u1 = 0,
/// ABRT_10ADDR1_NOACK [1:1]
/// This field indicates that the Master is in 10-bit address mode and the first 10-bit address byte was not acknowledged by any slave.\n\n
ABRT_10ADDR1_NOACK: u1 = 0,
/// ABRT_10ADDR2_NOACK [2:2]
/// This field indicates that the Master is in 10-bit address mode and that the second address byte of the 10-bit address was not acknowledged by any slave.\n\n
ABRT_10ADDR2_NOACK: u1 = 0,
/// ABRT_TXDATA_NOACK [3:3]
/// This field indicates the master-mode only bit. When the master receives an acknowledgement for the address, but when it sends data byte(s) following the address, it did not receive an acknowledge from the remote slave(s).\n\n
ABRT_TXDATA_NOACK: u1 = 0,
/// ABRT_GCALL_NOACK [4:4]
/// This field indicates that DW_apb_i2c in master mode has sent a General Call and no slave on the bus acknowledged the General Call.\n\n
ABRT_GCALL_NOACK: u1 = 0,
/// ABRT_GCALL_READ [5:5]
/// This field indicates that DW_apb_i2c in the master mode has sent a General Call but the user programmed the byte following the General Call to be a read from the bus (IC_DATA_CMD[9] is set to 1).\n\n
ABRT_GCALL_READ: u1 = 0,
/// ABRT_HS_ACKDET [6:6]
/// This field indicates that the Master is in High Speed mode and the High Speed Master code was acknowledged (wrong behavior).\n\n
ABRT_HS_ACKDET: u1 = 0,
/// ABRT_SBYTE_ACKDET [7:7]
/// This field indicates that the Master has sent a START Byte and the START Byte was acknowledged (wrong behavior).\n\n
ABRT_SBYTE_ACKDET: u1 = 0,
/// ABRT_HS_NORSTRT [8:8]
/// This field indicates that the restart is disabled (IC_RESTART_EN bit (IC_CON[5]) =0) and the user is trying to use the master to transfer data in High Speed mode.\n\n
ABRT_HS_NORSTRT: u1 = 0,
/// ABRT_SBYTE_NORSTRT [9:9]
/// To clear Bit 9, the source of the ABRT_SBYTE_NORSTRT must be fixed first; restart must be enabled (IC_CON[5]=1), the SPECIAL bit must be cleared (IC_TAR[11]), or the GC_OR_START bit must be cleared (IC_TAR[10]). Once the source of the ABRT_SBYTE_NORSTRT is fixed, then this bit can be cleared in the same manner as other bits in this register. If the source of the ABRT_SBYTE_NORSTRT is not fixed before attempting to clear this bit, bit 9 clears for one cycle and then gets reasserted. When this field is set to 1, the restart is disabled (IC_RESTART_EN bit (IC_CON[5]) =0) and the user is trying to send a START Byte.\n\n
ABRT_SBYTE_NORSTRT: u1 = 0,
/// ABRT_10B_RD_NORSTRT [10:10]
/// This field indicates that the restart is disabled (IC_RESTART_EN bit (IC_CON[5]) =0) and the master sends a read command in 10-bit addressing mode.\n\n
ABRT_10B_RD_NORSTRT: u1 = 0,
/// ABRT_MASTER_DIS [11:11]
/// This field indicates that the User tries to initiate a Master operation with the Master mode disabled.\n\n
ABRT_MASTER_DIS: u1 = 0,
/// ARB_LOST [12:12]
/// This field specifies that the Master has lost arbitration, or if IC_TX_ABRT_SOURCE[14] is also set, then the slave transmitter has lost arbitration.\n\n
ARB_LOST: u1 = 0,
/// ABRT_SLVFLUSH_TXFIFO [13:13]
/// This field specifies that the Slave has received a read command and some data exists in the TX FIFO, so the slave issues a TX_ABRT interrupt to flush old data in TX FIFO.\n\n
ABRT_SLVFLUSH_TXFIFO: u1 = 0,
/// ABRT_SLV_ARBLOST [14:14]
/// This field indicates that a Slave has lost the bus while transmitting data to a remote master. IC_TX_ABRT_SOURCE[12] is set at the same time. Note:  Even though the slave never 'owns' the bus, something could go wrong on the bus. This is a fail safe check. For instance, during a data transmission at the low-to-high transition of SCL, if what is on the data bus is not what is supposed to be transmitted, then DW_apb_i2c no longer own the bus.\n\n
ABRT_SLV_ARBLOST: u1 = 0,
/// ABRT_SLVRD_INTX [15:15]
/// 1: When the processor side responds to a slave mode request for data to be transmitted to a remote master and user writes a 1 in CMD (bit 8) of IC_DATA_CMD register.\n\n
ABRT_SLVRD_INTX: u1 = 0,
/// ABRT_USER_ABRT [16:16]
/// This is a master-mode-only bit. Master has detected the transfer abort (IC_ENABLE[1])\n\n
ABRT_USER_ABRT: u1 = 0,
/// unused [17:22]
_unused17: u6 = 0,
/// TX_FLUSH_CNT [23:31]
/// This field indicates the number of Tx FIFO Data Commands which are flushed due to TX_ABRT interrupt. It is cleared whenever I2C is disabled.\n\n
TX_FLUSH_CNT: u9 = 0,
};
/// I2C Transmit Abort Source Register\n\n
pub const IC_TX_ABRT_SOURCE = Register(IC_TX_ABRT_SOURCE_val).init(base_address + 0x80);

/// IC_SDA_HOLD
const IC_SDA_HOLD_val = packed struct {
/// IC_SDA_TX_HOLD [0:15]
/// Sets the required SDA hold time in units of ic_clk period, when DW_apb_i2c acts as a transmitter.\n\n
IC_SDA_TX_HOLD: u16 = 1,
/// IC_SDA_RX_HOLD [16:23]
/// Sets the required SDA hold time in units of ic_clk period, when DW_apb_i2c acts as a receiver.\n\n
IC_SDA_RX_HOLD: u8 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// I2C SDA Hold Time Length Register\n\n
pub const IC_SDA_HOLD = Register(IC_SDA_HOLD_val).init(base_address + 0x7c);

/// IC_RXFLR
const IC_RXFLR_val = packed struct {
/// RXFLR [0:4]
/// Receive FIFO Level. Contains the number of valid data entries in the receive FIFO.\n\n
RXFLR: u5 = 0,
/// unused [5:31]
_unused5: u3 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// I2C Receive FIFO Level Register This register contains the number of valid data entries in the receive FIFO buffer. It is cleared whenever: - The I2C is disabled - Whenever there is a transmit abort caused by any of the events tracked in IC_TX_ABRT_SOURCE The register increments whenever data is placed into the receive FIFO and decrements when data is taken from the receive FIFO.
pub const IC_RXFLR = Register(IC_RXFLR_val).init(base_address + 0x78);

/// IC_TXFLR
const IC_TXFLR_val = packed struct {
/// TXFLR [0:4]
/// Transmit FIFO Level. Contains the number of valid data entries in the transmit FIFO.\n\n
TXFLR: u5 = 0,
/// unused [5:31]
_unused5: u3 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// I2C Transmit FIFO Level Register This register contains the number of valid data entries in the transmit FIFO buffer. It is cleared whenever: - The I2C is disabled - There is a transmit abort - that is, TX_ABRT bit is set in the IC_RAW_INTR_STAT register - The slave bulk transmit mode is aborted The register increments whenever data is placed into the transmit FIFO and decrements when data is taken from the transmit FIFO.
pub const IC_TXFLR = Register(IC_TXFLR_val).init(base_address + 0x74);

/// IC_STATUS
const IC_STATUS_val = packed struct {
/// ACTIVITY [0:0]
/// I2C Activity Status. Reset value: 0x0
ACTIVITY: u1 = 0,
/// TFNF [1:1]
/// Transmit FIFO Not Full. Set when the transmit FIFO contains one or more empty locations, and is cleared when the FIFO is full. - 0: Transmit FIFO is full - 1: Transmit FIFO is not full Reset value: 0x1
TFNF: u1 = 1,
/// TFE [2:2]
/// Transmit FIFO Completely Empty. When the transmit FIFO is completely empty, this bit is set. When it contains one or more valid entries, this bit is cleared. This bit field does not request an interrupt. - 0: Transmit FIFO is not empty - 1: Transmit FIFO is empty Reset value: 0x1
TFE: u1 = 1,
/// RFNE [3:3]
/// Receive FIFO Not Empty. This bit is set when the receive FIFO contains one or more entries; it is cleared when the receive FIFO is empty. - 0: Receive FIFO is empty - 1: Receive FIFO is not empty Reset value: 0x0
RFNE: u1 = 0,
/// RFF [4:4]
/// Receive FIFO Completely Full. When the receive FIFO is completely full, this bit is set. When the receive FIFO contains one or more empty location, this bit is cleared. - 0: Receive FIFO is not full - 1: Receive FIFO is full Reset value: 0x0
RFF: u1 = 0,
/// MST_ACTIVITY [5:5]
/// Master FSM Activity Status. When the Master Finite State Machine (FSM) is not in the IDLE state, this bit is set. - 0: Master FSM is in IDLE state so the Master part of DW_apb_i2c is not Active - 1: Master FSM is not in IDLE state so the Master part of DW_apb_i2c is Active Note: IC_STATUS[0]-that is, ACTIVITY bit-is the OR of SLV_ACTIVITY and MST_ACTIVITY bits.\n\n
MST_ACTIVITY: u1 = 0,
/// SLV_ACTIVITY [6:6]
/// Slave FSM Activity Status. When the Slave Finite State Machine (FSM) is not in the IDLE state, this bit is set. - 0: Slave FSM is in IDLE state so the Slave part of DW_apb_i2c is not Active - 1: Slave FSM is not in IDLE state so the Slave part of DW_apb_i2c is Active Reset value: 0x0
SLV_ACTIVITY: u1 = 0,
/// unused [7:31]
_unused7: u1 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// I2C Status Register\n\n
pub const IC_STATUS = Register(IC_STATUS_val).init(base_address + 0x70);

/// IC_ENABLE
const IC_ENABLE_val = packed struct {
/// ENABLE [0:0]
/// Controls whether the DW_apb_i2c is enabled. - 0: Disables DW_apb_i2c (TX and RX FIFOs are held in an erased state) - 1: Enables DW_apb_i2c Software can disable DW_apb_i2c while it is active. However, it is important that care be taken to ensure that DW_apb_i2c is disabled properly. A recommended procedure is described in 'Disabling DW_apb_i2c'.\n\n
ENABLE: u1 = 0,
/// ABORT [1:1]
/// When set, the controller initiates the transfer abort. - 0: ABORT not initiated or ABORT done - 1: ABORT operation in progress The software can abort the I2C transfer in master mode by setting this bit. The software can set this bit only when ENABLE is already set; otherwise, the controller ignores any write to ABORT bit. The software cannot clear the ABORT bit once set. In response to an ABORT, the controller issues a STOP and flushes the Tx FIFO after completing the current transfer, then sets the TX_ABORT interrupt after the abort operation. The ABORT bit is cleared automatically after the abort operation.\n\n
ABORT: u1 = 0,
/// TX_CMD_BLOCK [2:2]
/// In Master mode: - 1'b1: Blocks the transmission of data on I2C bus even if Tx FIFO has data to transmit. - 1'b0: The transmission of data starts on I2C bus automatically, as soon as the first data is available in the Tx FIFO. Note: To block the execution of Master commands, set the TX_CMD_BLOCK bit only when Tx FIFO is empty (IC_STATUS[2]==1) and Master is in Idle state (IC_STATUS[5] == 0). Any further commands put in the Tx FIFO are not executed until TX_CMD_BLOCK bit is unset. Reset value:  IC_TX_CMD_BLOCK_DEFAULT
TX_CMD_BLOCK: u1 = 0,
/// unused [3:31]
_unused3: u5 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// I2C Enable Register
pub const IC_ENABLE = Register(IC_ENABLE_val).init(base_address + 0x6c);

/// IC_CLR_GEN_CALL
const IC_CLR_GEN_CALL_val = packed struct {
/// CLR_GEN_CALL [0:0]
/// Read this register to clear the GEN_CALL interrupt (bit 11) of IC_RAW_INTR_STAT register.\n\n
CLR_GEN_CALL: u1 = 0,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Clear GEN_CALL Interrupt Register
pub const IC_CLR_GEN_CALL = Register(IC_CLR_GEN_CALL_val).init(base_address + 0x68);

/// IC_CLR_START_DET
const IC_CLR_START_DET_val = packed struct {
/// CLR_START_DET [0:0]
/// Read this register to clear the START_DET interrupt (bit 10) of the IC_RAW_INTR_STAT register.\n\n
CLR_START_DET: u1 = 0,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Clear START_DET Interrupt Register
pub const IC_CLR_START_DET = Register(IC_CLR_START_DET_val).init(base_address + 0x64);

/// IC_CLR_STOP_DET
const IC_CLR_STOP_DET_val = packed struct {
/// CLR_STOP_DET [0:0]
/// Read this register to clear the STOP_DET interrupt (bit 9) of the IC_RAW_INTR_STAT register.\n\n
CLR_STOP_DET: u1 = 0,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Clear STOP_DET Interrupt Register
pub const IC_CLR_STOP_DET = Register(IC_CLR_STOP_DET_val).init(base_address + 0x60);

/// IC_CLR_ACTIVITY
const IC_CLR_ACTIVITY_val = packed struct {
/// CLR_ACTIVITY [0:0]
/// Reading this register clears the ACTIVITY interrupt if the I2C is not active anymore. If the I2C module is still active on the bus, the ACTIVITY interrupt bit continues to be set. It is automatically cleared by hardware if the module is disabled and if there is no further activity on the bus. The value read from this register to get status of the ACTIVITY interrupt (bit 8) of the IC_RAW_INTR_STAT register.\n\n
CLR_ACTIVITY: u1 = 0,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Clear ACTIVITY Interrupt Register
pub const IC_CLR_ACTIVITY = Register(IC_CLR_ACTIVITY_val).init(base_address + 0x5c);

/// IC_CLR_RX_DONE
const IC_CLR_RX_DONE_val = packed struct {
/// CLR_RX_DONE [0:0]
/// Read this register to clear the RX_DONE interrupt (bit 7) of the IC_RAW_INTR_STAT register.\n\n
CLR_RX_DONE: u1 = 0,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Clear RX_DONE Interrupt Register
pub const IC_CLR_RX_DONE = Register(IC_CLR_RX_DONE_val).init(base_address + 0x58);

/// IC_CLR_TX_ABRT
const IC_CLR_TX_ABRT_val = packed struct {
/// CLR_TX_ABRT [0:0]
/// Read this register to clear the TX_ABRT interrupt (bit 6) of the IC_RAW_INTR_STAT register, and the IC_TX_ABRT_SOURCE register. This also releases the TX FIFO from the flushed/reset state, allowing more writes to the TX FIFO. Refer to Bit 9 of the IC_TX_ABRT_SOURCE register for an exception to clearing IC_TX_ABRT_SOURCE.\n\n
CLR_TX_ABRT: u1 = 0,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Clear TX_ABRT Interrupt Register
pub const IC_CLR_TX_ABRT = Register(IC_CLR_TX_ABRT_val).init(base_address + 0x54);

/// IC_CLR_RD_REQ
const IC_CLR_RD_REQ_val = packed struct {
/// CLR_RD_REQ [0:0]
/// Read this register to clear the RD_REQ interrupt (bit 5) of the IC_RAW_INTR_STAT register.\n\n
CLR_RD_REQ: u1 = 0,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Clear RD_REQ Interrupt Register
pub const IC_CLR_RD_REQ = Register(IC_CLR_RD_REQ_val).init(base_address + 0x50);

/// IC_CLR_TX_OVER
const IC_CLR_TX_OVER_val = packed struct {
/// CLR_TX_OVER [0:0]
/// Read this register to clear the TX_OVER interrupt (bit 3) of the IC_RAW_INTR_STAT register.\n\n
CLR_TX_OVER: u1 = 0,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Clear TX_OVER Interrupt Register
pub const IC_CLR_TX_OVER = Register(IC_CLR_TX_OVER_val).init(base_address + 0x4c);

/// IC_CLR_RX_OVER
const IC_CLR_RX_OVER_val = packed struct {
/// CLR_RX_OVER [0:0]
/// Read this register to clear the RX_OVER interrupt (bit 1) of the IC_RAW_INTR_STAT register.\n\n
CLR_RX_OVER: u1 = 0,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Clear RX_OVER Interrupt Register
pub const IC_CLR_RX_OVER = Register(IC_CLR_RX_OVER_val).init(base_address + 0x48);

/// IC_CLR_RX_UNDER
const IC_CLR_RX_UNDER_val = packed struct {
/// CLR_RX_UNDER [0:0]
/// Read this register to clear the RX_UNDER interrupt (bit 0) of the IC_RAW_INTR_STAT register.\n\n
CLR_RX_UNDER: u1 = 0,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Clear RX_UNDER Interrupt Register
pub const IC_CLR_RX_UNDER = Register(IC_CLR_RX_UNDER_val).init(base_address + 0x44);

/// IC_CLR_INTR
const IC_CLR_INTR_val = packed struct {
/// CLR_INTR [0:0]
/// Read this register to clear the combined interrupt, all individual interrupts, and the IC_TX_ABRT_SOURCE register. This bit does not clear hardware clearable interrupts but software clearable interrupts. Refer to Bit 9 of the IC_TX_ABRT_SOURCE register for an exception to clearing IC_TX_ABRT_SOURCE.\n\n
CLR_INTR: u1 = 0,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Clear Combined and Individual Interrupt Register
pub const IC_CLR_INTR = Register(IC_CLR_INTR_val).init(base_address + 0x40);

/// IC_TX_TL
const IC_TX_TL_val = packed struct {
/// TX_TL [0:7]
/// Transmit FIFO Threshold Level.\n\n
TX_TL: u8 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// I2C Transmit FIFO Threshold Register
pub const IC_TX_TL = Register(IC_TX_TL_val).init(base_address + 0x3c);

/// IC_RX_TL
const IC_RX_TL_val = packed struct {
/// RX_TL [0:7]
/// Receive FIFO Threshold Level.\n\n
RX_TL: u8 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// I2C Receive FIFO Threshold Register
pub const IC_RX_TL = Register(IC_RX_TL_val).init(base_address + 0x38);

/// IC_RAW_INTR_STAT
const IC_RAW_INTR_STAT_val = packed struct {
/// RX_UNDER [0:0]
/// Set if the processor attempts to read the receive buffer when it is empty by reading from the IC_DATA_CMD register. If the module is disabled (IC_ENABLE[0]=0), this bit keeps its level until the master or slave state machines go into idle, and when ic_en goes to 0, this interrupt is cleared.\n\n
RX_UNDER: u1 = 0,
/// RX_OVER [1:1]
/// Set if the receive buffer is completely filled to IC_RX_BUFFER_DEPTH and an additional byte is received from an external I2C device. The DW_apb_i2c acknowledges this, but any data bytes received after the FIFO is full are lost. If the module is disabled (IC_ENABLE[0]=0), this bit keeps its level until the master or slave state machines go into idle, and when ic_en goes to 0, this interrupt is cleared.\n\n
RX_OVER: u1 = 0,
/// RX_FULL [2:2]
/// Set when the receive buffer reaches or goes above the RX_TL threshold in the IC_RX_TL register. It is automatically cleared by hardware when buffer level goes below the threshold. If the module is disabled (IC_ENABLE[0]=0), the RX FIFO is flushed and held in reset; therefore the RX FIFO is not full. So this bit is cleared once the IC_ENABLE bit 0 is programmed with a 0, regardless of the activity that continues.\n\n
RX_FULL: u1 = 0,
/// TX_OVER [3:3]
/// Set during transmit if the transmit buffer is filled to IC_TX_BUFFER_DEPTH and the processor attempts to issue another I2C command by writing to the IC_DATA_CMD register. When the module is disabled, this bit keeps its level until the master or slave state machines go into idle, and when ic_en goes to 0, this interrupt is cleared.\n\n
TX_OVER: u1 = 0,
/// TX_EMPTY [4:4]
/// The behavior of the TX_EMPTY interrupt status differs based on the TX_EMPTY_CTRL selection in the IC_CON register. - When TX_EMPTY_CTRL = 0: This bit is set to 1 when the transmit buffer is at or below the threshold value set in the IC_TX_TL register. - When TX_EMPTY_CTRL = 1: This bit is set to 1 when the transmit buffer is at or below the threshold value set in the IC_TX_TL register and the transmission of the address/data from the internal shift register for the most recently popped command is completed. It is automatically cleared by hardware when the buffer level goes above the threshold. When IC_ENABLE[0] is set to 0, the TX FIFO is flushed and held in reset. There the TX FIFO looks like it has no data within it, so this bit is set to 1, provided there is activity in the master or slave state machines. When there is no longer any activity, then with ic_en=0, this bit is set to 0.\n\n
TX_EMPTY: u1 = 0,
/// RD_REQ [5:5]
/// This bit is set to 1 when DW_apb_i2c is acting as a slave and another I2C master is attempting to read data from DW_apb_i2c. The DW_apb_i2c holds the I2C bus in a wait state (SCL=0) until this interrupt is serviced, which means that the slave has been addressed by a remote master that is asking for data to be transferred. The processor must respond to this interrupt and then write the requested data to the IC_DATA_CMD register. This bit is set to 0 just after the processor reads the IC_CLR_RD_REQ register.\n\n
RD_REQ: u1 = 0,
/// TX_ABRT [6:6]
/// This bit indicates if DW_apb_i2c, as an I2C transmitter, is unable to complete the intended actions on the contents of the transmit FIFO. This situation can occur both as an I2C master or an I2C slave, and is referred to as a 'transmit abort'. When this bit is set to 1, the IC_TX_ABRT_SOURCE register indicates the reason why the transmit abort takes places.\n\n
TX_ABRT: u1 = 0,
/// RX_DONE [7:7]
/// When the DW_apb_i2c is acting as a slave-transmitter, this bit is set to 1 if the master does not acknowledge a transmitted byte. This occurs on the last byte of the transmission, indicating that the transmission is done.\n\n
RX_DONE: u1 = 0,
/// ACTIVITY [8:8]
/// This bit captures DW_apb_i2c activity and stays set until it is cleared. There are four ways to clear it: - Disabling the DW_apb_i2c - Reading the IC_CLR_ACTIVITY register - Reading the IC_CLR_INTR register - System reset Once this bit is set, it stays set unless one of the four methods is used to clear it. Even if the DW_apb_i2c module is idle, this bit remains set until cleared, indicating that there was activity on the bus.\n\n
ACTIVITY: u1 = 0,
/// STOP_DET [9:9]
/// Indicates whether a STOP condition has occurred on the I2C interface regardless of whether DW_apb_i2c is operating in slave or master mode.\n\n
STOP_DET: u1 = 0,
/// START_DET [10:10]
/// Indicates whether a START or RESTART condition has occurred on the I2C interface regardless of whether DW_apb_i2c is operating in slave or master mode.\n\n
START_DET: u1 = 0,
/// GEN_CALL [11:11]
/// Set only when a General Call address is received and it is acknowledged. It stays set until it is cleared either by disabling DW_apb_i2c or when the CPU reads bit 0 of the IC_CLR_GEN_CALL register. DW_apb_i2c stores the received data in the Rx buffer.\n\n
GEN_CALL: u1 = 0,
/// RESTART_DET [12:12]
/// Indicates whether a RESTART condition has occurred on the I2C interface when DW_apb_i2c is operating in Slave mode and the slave is being addressed. Enabled only when IC_SLV_RESTART_DET_EN=1.\n\n
RESTART_DET: u1 = 0,
/// unused [13:31]
_unused13: u3 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// I2C Raw Interrupt Status Register\n\n
pub const IC_RAW_INTR_STAT = Register(IC_RAW_INTR_STAT_val).init(base_address + 0x34);

/// IC_INTR_MASK
const IC_INTR_MASK_val = packed struct {
/// M_RX_UNDER [0:0]
/// This bit masks the R_RX_UNDER interrupt in IC_INTR_STAT register.\n\n
M_RX_UNDER: u1 = 1,
/// M_RX_OVER [1:1]
/// This bit masks the R_RX_OVER interrupt in IC_INTR_STAT register.\n\n
M_RX_OVER: u1 = 1,
/// M_RX_FULL [2:2]
/// This bit masks the R_RX_FULL interrupt in IC_INTR_STAT register.\n\n
M_RX_FULL: u1 = 1,
/// M_TX_OVER [3:3]
/// This bit masks the R_TX_OVER interrupt in IC_INTR_STAT register.\n\n
M_TX_OVER: u1 = 1,
/// M_TX_EMPTY [4:4]
/// This bit masks the R_TX_EMPTY interrupt in IC_INTR_STAT register.\n\n
M_TX_EMPTY: u1 = 1,
/// M_RD_REQ [5:5]
/// This bit masks the R_RD_REQ interrupt in IC_INTR_STAT register.\n\n
M_RD_REQ: u1 = 1,
/// M_TX_ABRT [6:6]
/// This bit masks the R_TX_ABRT interrupt in IC_INTR_STAT register.\n\n
M_TX_ABRT: u1 = 1,
/// M_RX_DONE [7:7]
/// This bit masks the R_RX_DONE interrupt in IC_INTR_STAT register.\n\n
M_RX_DONE: u1 = 1,
/// M_ACTIVITY [8:8]
/// This bit masks the R_ACTIVITY interrupt in IC_INTR_STAT register.\n\n
M_ACTIVITY: u1 = 0,
/// M_STOP_DET [9:9]
/// This bit masks the R_STOP_DET interrupt in IC_INTR_STAT register.\n\n
M_STOP_DET: u1 = 0,
/// M_START_DET [10:10]
/// This bit masks the R_START_DET interrupt in IC_INTR_STAT register.\n\n
M_START_DET: u1 = 0,
/// M_GEN_CALL [11:11]
/// This bit masks the R_GEN_CALL interrupt in IC_INTR_STAT register.\n\n
M_GEN_CALL: u1 = 1,
/// M_RESTART_DET [12:12]
/// This bit masks the R_RESTART_DET interrupt in IC_INTR_STAT register.\n\n
M_RESTART_DET: u1 = 0,
/// unused [13:31]
_unused13: u3 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// I2C Interrupt Mask Register.\n\n
pub const IC_INTR_MASK = Register(IC_INTR_MASK_val).init(base_address + 0x30);

/// IC_INTR_STAT
const IC_INTR_STAT_val = packed struct {
/// R_RX_UNDER [0:0]
/// See IC_RAW_INTR_STAT for a detailed description of R_RX_UNDER bit.\n\n
R_RX_UNDER: u1 = 0,
/// R_RX_OVER [1:1]
/// See IC_RAW_INTR_STAT for a detailed description of R_RX_OVER bit.\n\n
R_RX_OVER: u1 = 0,
/// R_RX_FULL [2:2]
/// See IC_RAW_INTR_STAT for a detailed description of R_RX_FULL bit.\n\n
R_RX_FULL: u1 = 0,
/// R_TX_OVER [3:3]
/// See IC_RAW_INTR_STAT for a detailed description of R_TX_OVER bit.\n\n
R_TX_OVER: u1 = 0,
/// R_TX_EMPTY [4:4]
/// See IC_RAW_INTR_STAT for a detailed description of R_TX_EMPTY bit.\n\n
R_TX_EMPTY: u1 = 0,
/// R_RD_REQ [5:5]
/// See IC_RAW_INTR_STAT for a detailed description of R_RD_REQ bit.\n\n
R_RD_REQ: u1 = 0,
/// R_TX_ABRT [6:6]
/// See IC_RAW_INTR_STAT for a detailed description of R_TX_ABRT bit.\n\n
R_TX_ABRT: u1 = 0,
/// R_RX_DONE [7:7]
/// See IC_RAW_INTR_STAT for a detailed description of R_RX_DONE bit.\n\n
R_RX_DONE: u1 = 0,
/// R_ACTIVITY [8:8]
/// See IC_RAW_INTR_STAT for a detailed description of R_ACTIVITY bit.\n\n
R_ACTIVITY: u1 = 0,
/// R_STOP_DET [9:9]
/// See IC_RAW_INTR_STAT for a detailed description of R_STOP_DET bit.\n\n
R_STOP_DET: u1 = 0,
/// R_START_DET [10:10]
/// See IC_RAW_INTR_STAT for a detailed description of R_START_DET bit.\n\n
R_START_DET: u1 = 0,
/// R_GEN_CALL [11:11]
/// See IC_RAW_INTR_STAT for a detailed description of R_GEN_CALL bit.\n\n
R_GEN_CALL: u1 = 0,
/// R_RESTART_DET [12:12]
/// See IC_RAW_INTR_STAT for a detailed description of R_RESTART_DET bit.\n\n
R_RESTART_DET: u1 = 0,
/// unused [13:31]
_unused13: u3 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// I2C Interrupt Status Register\n\n
pub const IC_INTR_STAT = Register(IC_INTR_STAT_val).init(base_address + 0x2c);

/// IC_FS_SCL_LCNT
const IC_FS_SCL_LCNT_val = packed struct {
/// IC_FS_SCL_LCNT [0:15]
/// This register must be set before any I2C bus transaction can take place to ensure proper I/O timing. This register sets the SCL clock low period count for fast speed. It is used in high-speed mode to send the Master Code and START BYTE or General CALL. For more information, refer to 'IC_CLK Frequency Configuration'.\n\n
IC_FS_SCL_LCNT: u16 = 13,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Fast Mode or Fast Mode Plus I2C Clock SCL Low Count Register
pub const IC_FS_SCL_LCNT = Register(IC_FS_SCL_LCNT_val).init(base_address + 0x20);

/// IC_FS_SCL_HCNT
const IC_FS_SCL_HCNT_val = packed struct {
/// IC_FS_SCL_HCNT [0:15]
/// This register must be set before any I2C bus transaction can take place to ensure proper I/O timing. This register sets the SCL clock high-period count for fast mode or fast mode plus. It is used in high-speed mode to send the Master Code and START BYTE or General CALL. For more information, refer to 'IC_CLK Frequency Configuration'.\n\n
IC_FS_SCL_HCNT: u16 = 6,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Fast Mode or Fast Mode Plus I2C Clock SCL High Count Register
pub const IC_FS_SCL_HCNT = Register(IC_FS_SCL_HCNT_val).init(base_address + 0x1c);

/// IC_SS_SCL_LCNT
const IC_SS_SCL_LCNT_val = packed struct {
/// IC_SS_SCL_LCNT [0:15]
/// This register must be set before any I2C bus transaction can take place to ensure proper I/O timing. This register sets the SCL clock low period count for standard speed. For more information, refer to 'IC_CLK Frequency Configuration'\n\n
IC_SS_SCL_LCNT: u16 = 47,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Standard Speed I2C Clock SCL Low Count Register
pub const IC_SS_SCL_LCNT = Register(IC_SS_SCL_LCNT_val).init(base_address + 0x18);

/// IC_SS_SCL_HCNT
const IC_SS_SCL_HCNT_val = packed struct {
/// IC_SS_SCL_HCNT [0:15]
/// This register must be set before any I2C bus transaction can take place to ensure proper I/O timing. This register sets the SCL clock high-period count for standard speed. For more information, refer to 'IC_CLK Frequency Configuration'.\n\n
IC_SS_SCL_HCNT: u16 = 40,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Standard Speed I2C Clock SCL High Count Register
pub const IC_SS_SCL_HCNT = Register(IC_SS_SCL_HCNT_val).init(base_address + 0x14);

/// IC_DATA_CMD
const IC_DATA_CMD_val = packed struct {
/// DAT [0:7]
/// This register contains the data to be transmitted or received on the I2C bus. If you are writing to this register and want to perform a read, bits 7:0 (DAT) are ignored by the DW_apb_i2c. However, when you read this register, these bits return the value of data received on the DW_apb_i2c interface.\n\n
DAT: u8 = 0,
/// CMD [8:8]
/// This bit controls whether a read or a write is performed. This bit does not control the direction when the DW_apb_i2con acts as a slave. It controls only the direction when it acts as a master.\n\n
CMD: u1 = 0,
/// STOP [9:9]
/// This bit controls whether a STOP is issued after the byte is sent or received.\n\n
STOP: u1 = 0,
/// RESTART [10:10]
/// This bit controls whether a RESTART is issued before the byte is sent or received.\n\n
RESTART: u1 = 0,
/// FIRST_DATA_BYTE [11:11]
/// Indicates the first data byte received after the address phase for receive transfer in Master receiver or Slave receiver mode.\n\n
FIRST_DATA_BYTE: u1 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// I2C Rx/Tx Data Buffer and Command Register; this is the register the CPU writes to when filling the TX FIFO and the CPU reads from when retrieving bytes from RX FIFO.\n\n
pub const IC_DATA_CMD = Register(IC_DATA_CMD_val).init(base_address + 0x10);

/// IC_SAR
const IC_SAR_val = packed struct {
/// IC_SAR [0:9]
/// The IC_SAR holds the slave address when the I2C is operating as a slave. For 7-bit addressing, only IC_SAR[6:0] is used.\n\n
IC_SAR: u10 = 85,
/// unused [10:31]
_unused10: u6 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// I2C Slave Address Register
pub const IC_SAR = Register(IC_SAR_val).init(base_address + 0x8);

/// IC_TAR
const IC_TAR_val = packed struct {
/// IC_TAR [0:9]
/// This is the target address for any master transaction. When transmitting a General Call, these bits are ignored. To generate a START BYTE, the CPU needs to write only once into these bits.\n\n
IC_TAR: u10 = 85,
/// GC_OR_START [10:10]
/// If bit 11 (SPECIAL) is set to 1 and bit 13(Device-ID) is set to 0, then this bit indicates whether a General Call or START byte command is to be performed by the DW_apb_i2c. - 0: General Call Address - after issuing a General Call, only writes may be performed. Attempting to issue a read command results in setting bit 6 (TX_ABRT) of the IC_RAW_INTR_STAT register. The DW_apb_i2c remains in General Call mode until the SPECIAL bit value (bit 11) is cleared. - 1: START BYTE Reset value: 0x0
GC_OR_START: u1 = 0,
/// SPECIAL [11:11]
/// This bit indicates whether software performs a Device-ID or General Call or START BYTE command. - 0: ignore bit 10 GC_OR_START and use IC_TAR normally - 1: perform special I2C command as specified in Device_ID or GC_OR_START bit Reset value: 0x0
SPECIAL: u1 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// I2C Target Address Register\n\n
pub const IC_TAR = Register(IC_TAR_val).init(base_address + 0x4);

/// IC_CON
const IC_CON_val = packed struct {
/// MASTER_MODE [0:0]
/// This bit controls whether the DW_apb_i2c master is enabled.\n\n
MASTER_MODE: u1 = 1,
/// SPEED [1:2]
/// These bits control at which speed the DW_apb_i2c operates; its setting is relevant only if one is operating the DW_apb_i2c in master mode. Hardware protects against illegal values being programmed by software. These bits must be programmed appropriately for slave mode also, as it is used to capture correct value of spike filter as per the speed mode.\n\n
SPEED: u2 = 2,
/// IC_10BITADDR_SLAVE [3:3]
/// When acting as a slave, this bit controls whether the DW_apb_i2c responds to 7- or 10-bit addresses. - 0: 7-bit addressing. The DW_apb_i2c ignores transactions that involve 10-bit addressing; for 7-bit addressing, only the lower 7 bits of the IC_SAR register are compared. - 1: 10-bit addressing. The DW_apb_i2c responds to only 10-bit addressing transfers that match the full 10 bits of the IC_SAR register.
IC_10BITADDR_SLAVE: u1 = 0,
/// IC_10BITADDR_MASTER [4:4]
/// Controls whether the DW_apb_i2c starts its transfers in 7- or 10-bit addressing mode when acting as a master. - 0: 7-bit addressing - 1: 10-bit addressing
IC_10BITADDR_MASTER: u1 = 0,
/// IC_RESTART_EN [5:5]
/// Determines whether RESTART conditions may be sent when acting as a master. Some older slaves do not support handling RESTART conditions; however, RESTART conditions are used in several DW_apb_i2c operations. When RESTART is disabled, the master is prohibited from performing the following functions: - Sending a START BYTE - Performing any high-speed mode operation - High-speed mode operation - Performing direction changes in combined format mode - Performing a read operation with a 10-bit address By replacing RESTART condition followed by a STOP and a subsequent START condition, split operations are broken down into multiple DW_apb_i2c transfers. If the above operations are performed, it will result in setting bit 6 (TX_ABRT) of the IC_RAW_INTR_STAT register.\n\n
IC_RESTART_EN: u1 = 1,
/// IC_SLAVE_DISABLE [6:6]
/// This bit controls whether I2C has its slave disabled, which means once the presetn signal is applied, then this bit is set and the slave is disabled.\n\n
IC_SLAVE_DISABLE: u1 = 1,
/// STOP_DET_IFADDRESSED [7:7]
/// In slave mode: - 1'b1:  issues the STOP_DET interrupt only when it is addressed. - 1'b0:  issues the STOP_DET irrespective of whether it's addressed or not. Reset value: 0x0\n\n
STOP_DET_IFADDRESSED: u1 = 0,
/// TX_EMPTY_CTRL [8:8]
/// This bit controls the generation of the TX_EMPTY interrupt, as described in the IC_RAW_INTR_STAT register.\n\n
TX_EMPTY_CTRL: u1 = 0,
/// RX_FIFO_FULL_HLD_CTRL [9:9]
/// This bit controls whether DW_apb_i2c should hold the bus when the Rx FIFO is physically full to its RX_BUFFER_DEPTH, as described in the IC_RX_FULL_HLD_BUS_EN parameter.\n\n
RX_FIFO_FULL_HLD_CTRL: u1 = 0,
/// STOP_DET_IF_MASTER_ACTIVE [10:10]
/// Master issues the STOP_DET interrupt irrespective of whether master is active or not
STOP_DET_IF_MASTER_ACTIVE: u1 = 0,
/// unused [11:31]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// I2C Control Register. This register can be written only when the DW_apb_i2c is disabled, which corresponds to the IC_ENABLE[0] register being set to 0. Writes at other times have no effect.\n\n
pub const IC_CON = Register(IC_CON_val).init(base_address + 0x0);
};

/// DW_apb_i2c address block
pub const I2C1 = struct {

const base_address = 0x40048000;
/// IC_COMP_TYPE
const IC_COMP_TYPE_val = packed struct {
/// IC_COMP_TYPE [0:31]
/// Designware Component Type number = 0x44_57_01_40. This assigned unique hex value is constant and is derived from the two ASCII letters 'DW' followed by a 16-bit unsigned number.
IC_COMP_TYPE: u32 = 1146552640,
};
/// I2C Component Type Register
pub const IC_COMP_TYPE = Register(IC_COMP_TYPE_val).init(base_address + 0xfc);

/// IC_COMP_VERSION
const IC_COMP_VERSION_val = packed struct {
/// IC_COMP_VERSION [0:31]
/// No description
IC_COMP_VERSION: u32 = 842019114,
};
/// I2C Component Version Register
pub const IC_COMP_VERSION = Register(IC_COMP_VERSION_val).init(base_address + 0xf8);

/// IC_COMP_PARAM_1
const IC_COMP_PARAM_1_val = packed struct {
/// APB_DATA_WIDTH [0:1]
/// APB data bus width is 32 bits
APB_DATA_WIDTH: u2 = 0,
/// MAX_SPEED_MODE [2:3]
/// MAX SPEED MODE = FAST MODE
MAX_SPEED_MODE: u2 = 0,
/// HC_COUNT_VALUES [4:4]
/// Programmable count values for each mode.
HC_COUNT_VALUES: u1 = 0,
/// INTR_IO [5:5]
/// COMBINED Interrupt outputs
INTR_IO: u1 = 0,
/// HAS_DMA [6:6]
/// DMA handshaking signals are enabled
HAS_DMA: u1 = 0,
/// ADD_ENCODED_PARAMS [7:7]
/// Encoded parameters not visible
ADD_ENCODED_PARAMS: u1 = 0,
/// RX_BUFFER_DEPTH [8:15]
/// RX Buffer Depth = 16
RX_BUFFER_DEPTH: u8 = 0,
/// TX_BUFFER_DEPTH [16:23]
/// TX Buffer Depth = 16
TX_BUFFER_DEPTH: u8 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// Component Parameter Register 1\n\n
pub const IC_COMP_PARAM_1 = Register(IC_COMP_PARAM_1_val).init(base_address + 0xf4);

/// IC_CLR_RESTART_DET
const IC_CLR_RESTART_DET_val = packed struct {
/// CLR_RESTART_DET [0:0]
/// Read this register to clear the RESTART_DET interrupt (bit 12) of IC_RAW_INTR_STAT register.\n\n
CLR_RESTART_DET: u1 = 0,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Clear RESTART_DET Interrupt Register
pub const IC_CLR_RESTART_DET = Register(IC_CLR_RESTART_DET_val).init(base_address + 0xa8);

/// IC_FS_SPKLEN
const IC_FS_SPKLEN_val = packed struct {
/// IC_FS_SPKLEN [0:7]
/// This register must be set before any I2C bus transaction can take place to ensure stable operation. This register sets the duration, measured in ic_clk cycles, of the longest spike in the SCL or SDA lines that will be filtered out by the spike suppression logic. This register can be written only when the I2C interface is disabled which corresponds to the IC_ENABLE[0] register being set to 0. Writes at other times have no effect. The minimum valid value is 1; hardware prevents values less than this being written, and if attempted results in 1 being set. or more information, refer to 'Spike Suppression'.
IC_FS_SPKLEN: u8 = 7,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// I2C SS, FS or FM+ spike suppression limit\n\n
pub const IC_FS_SPKLEN = Register(IC_FS_SPKLEN_val).init(base_address + 0xa0);

/// IC_ENABLE_STATUS
const IC_ENABLE_STATUS_val = packed struct {
/// IC_EN [0:0]
/// ic_en Status. This bit always reflects the value driven on the output port ic_en. - When read as 1, DW_apb_i2c is deemed to be in an enabled state. - When read as 0, DW_apb_i2c is deemed completely inactive. Note:  The CPU can safely read this bit anytime. When this bit is read as 0, the CPU can safely read SLV_RX_DATA_LOST (bit 2) and SLV_DISABLED_WHILE_BUSY (bit 1).\n\n
IC_EN: u1 = 0,
/// SLV_DISABLED_WHILE_BUSY [1:1]
/// Slave Disabled While Busy (Transmit, Receive). This bit indicates if a potential or active Slave operation has been aborted due to the setting bit 0 of the IC_ENABLE register from 1 to 0. This bit is set when the CPU writes a 0 to the IC_ENABLE register while:\n\n
SLV_DISABLED_WHILE_BUSY: u1 = 0,
/// SLV_RX_DATA_LOST [2:2]
/// Slave Received Data Lost. This bit indicates if a Slave-Receiver operation has been aborted with at least one data byte received from an I2C transfer due to the setting bit 0 of IC_ENABLE from 1 to 0. When read as 1, DW_apb_i2c is deemed to have been actively engaged in an aborted I2C transfer (with matching address) and the data phase of the I2C transfer has been entered, even though a data byte has been responded with a NACK.\n\n
SLV_RX_DATA_LOST: u1 = 0,
/// unused [3:31]
_unused3: u5 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// I2C Enable Status Register\n\n
pub const IC_ENABLE_STATUS = Register(IC_ENABLE_STATUS_val).init(base_address + 0x9c);

/// IC_ACK_GENERAL_CALL
const IC_ACK_GENERAL_CALL_val = packed struct {
/// ACK_GEN_CALL [0:0]
/// ACK General Call. When set to 1, DW_apb_i2c responds with a ACK (by asserting ic_data_oe) when it receives a General Call. Otherwise, DW_apb_i2c responds with a NACK (by negating ic_data_oe).
ACK_GEN_CALL: u1 = 1,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// I2C ACK General Call Register\n\n
pub const IC_ACK_GENERAL_CALL = Register(IC_ACK_GENERAL_CALL_val).init(base_address + 0x98);

/// IC_SDA_SETUP
const IC_SDA_SETUP_val = packed struct {
/// SDA_SETUP [0:7]
/// SDA Setup. It is recommended that if the required delay is 1000ns, then for an ic_clk frequency of 10 MHz, IC_SDA_SETUP should be programmed to a value of 11. IC_SDA_SETUP must be programmed with a minimum value of 2.
SDA_SETUP: u8 = 100,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// I2C SDA Setup Register\n\n
pub const IC_SDA_SETUP = Register(IC_SDA_SETUP_val).init(base_address + 0x94);

/// IC_DMA_RDLR
const IC_DMA_RDLR_val = packed struct {
/// DMARDL [0:3]
/// Receive Data Level. This bit field controls the level at which a DMA request is made by the receive logic. The watermark level = DMARDL+1; that is, dma_rx_req is generated when the number of valid data entries in the receive FIFO is equal to or more than this field value + 1, and RDMAE =1. For instance, when DMARDL is 0, then dma_rx_req is asserted when 1 or more data entries are present in the receive FIFO.\n\n
DMARDL: u4 = 0,
/// unused [4:31]
_unused4: u4 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// I2C Receive Data Level Register
pub const IC_DMA_RDLR = Register(IC_DMA_RDLR_val).init(base_address + 0x90);

/// IC_DMA_TDLR
const IC_DMA_TDLR_val = packed struct {
/// DMATDL [0:3]
/// Transmit Data Level. This bit field controls the level at which a DMA request is made by the transmit logic. It is equal to the watermark level; that is, the dma_tx_req signal is generated when the number of valid data entries in the transmit FIFO is equal to or below this field value, and TDMAE = 1.\n\n
DMATDL: u4 = 0,
/// unused [4:31]
_unused4: u4 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// DMA Transmit Data Level Register
pub const IC_DMA_TDLR = Register(IC_DMA_TDLR_val).init(base_address + 0x8c);

/// IC_DMA_CR
const IC_DMA_CR_val = packed struct {
/// RDMAE [0:0]
/// Receive DMA Enable. This bit enables/disables the receive FIFO DMA channel. Reset value: 0x0
RDMAE: u1 = 0,
/// TDMAE [1:1]
/// Transmit DMA Enable. This bit enables/disables the transmit FIFO DMA channel. Reset value: 0x0
TDMAE: u1 = 0,
/// unused [2:31]
_unused2: u6 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// DMA Control Register\n\n
pub const IC_DMA_CR = Register(IC_DMA_CR_val).init(base_address + 0x88);

/// IC_SLV_DATA_NACK_ONLY
const IC_SLV_DATA_NACK_ONLY_val = packed struct {
/// NACK [0:0]
/// Generate NACK. This NACK generation only occurs when DW_apb_i2c is a slave-receiver. If this register is set to a value of 1, it can only generate a NACK after a data byte is received; hence, the data transfer is aborted and the data received is not pushed to the receive buffer.\n\n
NACK: u1 = 0,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Generate Slave Data NACK Register\n\n
pub const IC_SLV_DATA_NACK_ONLY = Register(IC_SLV_DATA_NACK_ONLY_val).init(base_address + 0x84);

/// IC_TX_ABRT_SOURCE
const IC_TX_ABRT_SOURCE_val = packed struct {
/// ABRT_7B_ADDR_NOACK [0:0]
/// This field indicates that the Master is in 7-bit addressing mode and the address sent was not acknowledged by any slave.\n\n
ABRT_7B_ADDR_NOACK: u1 = 0,
/// ABRT_10ADDR1_NOACK [1:1]
/// This field indicates that the Master is in 10-bit address mode and the first 10-bit address byte was not acknowledged by any slave.\n\n
ABRT_10ADDR1_NOACK: u1 = 0,
/// ABRT_10ADDR2_NOACK [2:2]
/// This field indicates that the Master is in 10-bit address mode and that the second address byte of the 10-bit address was not acknowledged by any slave.\n\n
ABRT_10ADDR2_NOACK: u1 = 0,
/// ABRT_TXDATA_NOACK [3:3]
/// This field indicates the master-mode only bit. When the master receives an acknowledgement for the address, but when it sends data byte(s) following the address, it did not receive an acknowledge from the remote slave(s).\n\n
ABRT_TXDATA_NOACK: u1 = 0,
/// ABRT_GCALL_NOACK [4:4]
/// This field indicates that DW_apb_i2c in master mode has sent a General Call and no slave on the bus acknowledged the General Call.\n\n
ABRT_GCALL_NOACK: u1 = 0,
/// ABRT_GCALL_READ [5:5]
/// This field indicates that DW_apb_i2c in the master mode has sent a General Call but the user programmed the byte following the General Call to be a read from the bus (IC_DATA_CMD[9] is set to 1).\n\n
ABRT_GCALL_READ: u1 = 0,
/// ABRT_HS_ACKDET [6:6]
/// This field indicates that the Master is in High Speed mode and the High Speed Master code was acknowledged (wrong behavior).\n\n
ABRT_HS_ACKDET: u1 = 0,
/// ABRT_SBYTE_ACKDET [7:7]
/// This field indicates that the Master has sent a START Byte and the START Byte was acknowledged (wrong behavior).\n\n
ABRT_SBYTE_ACKDET: u1 = 0,
/// ABRT_HS_NORSTRT [8:8]
/// This field indicates that the restart is disabled (IC_RESTART_EN bit (IC_CON[5]) =0) and the user is trying to use the master to transfer data in High Speed mode.\n\n
ABRT_HS_NORSTRT: u1 = 0,
/// ABRT_SBYTE_NORSTRT [9:9]
/// To clear Bit 9, the source of the ABRT_SBYTE_NORSTRT must be fixed first; restart must be enabled (IC_CON[5]=1), the SPECIAL bit must be cleared (IC_TAR[11]), or the GC_OR_START bit must be cleared (IC_TAR[10]). Once the source of the ABRT_SBYTE_NORSTRT is fixed, then this bit can be cleared in the same manner as other bits in this register. If the source of the ABRT_SBYTE_NORSTRT is not fixed before attempting to clear this bit, bit 9 clears for one cycle and then gets reasserted. When this field is set to 1, the restart is disabled (IC_RESTART_EN bit (IC_CON[5]) =0) and the user is trying to send a START Byte.\n\n
ABRT_SBYTE_NORSTRT: u1 = 0,
/// ABRT_10B_RD_NORSTRT [10:10]
/// This field indicates that the restart is disabled (IC_RESTART_EN bit (IC_CON[5]) =0) and the master sends a read command in 10-bit addressing mode.\n\n
ABRT_10B_RD_NORSTRT: u1 = 0,
/// ABRT_MASTER_DIS [11:11]
/// This field indicates that the User tries to initiate a Master operation with the Master mode disabled.\n\n
ABRT_MASTER_DIS: u1 = 0,
/// ARB_LOST [12:12]
/// This field specifies that the Master has lost arbitration, or if IC_TX_ABRT_SOURCE[14] is also set, then the slave transmitter has lost arbitration.\n\n
ARB_LOST: u1 = 0,
/// ABRT_SLVFLUSH_TXFIFO [13:13]
/// This field specifies that the Slave has received a read command and some data exists in the TX FIFO, so the slave issues a TX_ABRT interrupt to flush old data in TX FIFO.\n\n
ABRT_SLVFLUSH_TXFIFO: u1 = 0,
/// ABRT_SLV_ARBLOST [14:14]
/// This field indicates that a Slave has lost the bus while transmitting data to a remote master. IC_TX_ABRT_SOURCE[12] is set at the same time. Note:  Even though the slave never 'owns' the bus, something could go wrong on the bus. This is a fail safe check. For instance, during a data transmission at the low-to-high transition of SCL, if what is on the data bus is not what is supposed to be transmitted, then DW_apb_i2c no longer own the bus.\n\n
ABRT_SLV_ARBLOST: u1 = 0,
/// ABRT_SLVRD_INTX [15:15]
/// 1: When the processor side responds to a slave mode request for data to be transmitted to a remote master and user writes a 1 in CMD (bit 8) of IC_DATA_CMD register.\n\n
ABRT_SLVRD_INTX: u1 = 0,
/// ABRT_USER_ABRT [16:16]
/// This is a master-mode-only bit. Master has detected the transfer abort (IC_ENABLE[1])\n\n
ABRT_USER_ABRT: u1 = 0,
/// unused [17:22]
_unused17: u6 = 0,
/// TX_FLUSH_CNT [23:31]
/// This field indicates the number of Tx FIFO Data Commands which are flushed due to TX_ABRT interrupt. It is cleared whenever I2C is disabled.\n\n
TX_FLUSH_CNT: u9 = 0,
};
/// I2C Transmit Abort Source Register\n\n
pub const IC_TX_ABRT_SOURCE = Register(IC_TX_ABRT_SOURCE_val).init(base_address + 0x80);

/// IC_SDA_HOLD
const IC_SDA_HOLD_val = packed struct {
/// IC_SDA_TX_HOLD [0:15]
/// Sets the required SDA hold time in units of ic_clk period, when DW_apb_i2c acts as a transmitter.\n\n
IC_SDA_TX_HOLD: u16 = 1,
/// IC_SDA_RX_HOLD [16:23]
/// Sets the required SDA hold time in units of ic_clk period, when DW_apb_i2c acts as a receiver.\n\n
IC_SDA_RX_HOLD: u8 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// I2C SDA Hold Time Length Register\n\n
pub const IC_SDA_HOLD = Register(IC_SDA_HOLD_val).init(base_address + 0x7c);

/// IC_RXFLR
const IC_RXFLR_val = packed struct {
/// RXFLR [0:4]
/// Receive FIFO Level. Contains the number of valid data entries in the receive FIFO.\n\n
RXFLR: u5 = 0,
/// unused [5:31]
_unused5: u3 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// I2C Receive FIFO Level Register This register contains the number of valid data entries in the receive FIFO buffer. It is cleared whenever: - The I2C is disabled - Whenever there is a transmit abort caused by any of the events tracked in IC_TX_ABRT_SOURCE The register increments whenever data is placed into the receive FIFO and decrements when data is taken from the receive FIFO.
pub const IC_RXFLR = Register(IC_RXFLR_val).init(base_address + 0x78);

/// IC_TXFLR
const IC_TXFLR_val = packed struct {
/// TXFLR [0:4]
/// Transmit FIFO Level. Contains the number of valid data entries in the transmit FIFO.\n\n
TXFLR: u5 = 0,
/// unused [5:31]
_unused5: u3 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// I2C Transmit FIFO Level Register This register contains the number of valid data entries in the transmit FIFO buffer. It is cleared whenever: - The I2C is disabled - There is a transmit abort - that is, TX_ABRT bit is set in the IC_RAW_INTR_STAT register - The slave bulk transmit mode is aborted The register increments whenever data is placed into the transmit FIFO and decrements when data is taken from the transmit FIFO.
pub const IC_TXFLR = Register(IC_TXFLR_val).init(base_address + 0x74);

/// IC_STATUS
const IC_STATUS_val = packed struct {
/// ACTIVITY [0:0]
/// I2C Activity Status. Reset value: 0x0
ACTIVITY: u1 = 0,
/// TFNF [1:1]
/// Transmit FIFO Not Full. Set when the transmit FIFO contains one or more empty locations, and is cleared when the FIFO is full. - 0: Transmit FIFO is full - 1: Transmit FIFO is not full Reset value: 0x1
TFNF: u1 = 1,
/// TFE [2:2]
/// Transmit FIFO Completely Empty. When the transmit FIFO is completely empty, this bit is set. When it contains one or more valid entries, this bit is cleared. This bit field does not request an interrupt. - 0: Transmit FIFO is not empty - 1: Transmit FIFO is empty Reset value: 0x1
TFE: u1 = 1,
/// RFNE [3:3]
/// Receive FIFO Not Empty. This bit is set when the receive FIFO contains one or more entries; it is cleared when the receive FIFO is empty. - 0: Receive FIFO is empty - 1: Receive FIFO is not empty Reset value: 0x0
RFNE: u1 = 0,
/// RFF [4:4]
/// Receive FIFO Completely Full. When the receive FIFO is completely full, this bit is set. When the receive FIFO contains one or more empty location, this bit is cleared. - 0: Receive FIFO is not full - 1: Receive FIFO is full Reset value: 0x0
RFF: u1 = 0,
/// MST_ACTIVITY [5:5]
/// Master FSM Activity Status. When the Master Finite State Machine (FSM) is not in the IDLE state, this bit is set. - 0: Master FSM is in IDLE state so the Master part of DW_apb_i2c is not Active - 1: Master FSM is not in IDLE state so the Master part of DW_apb_i2c is Active Note: IC_STATUS[0]-that is, ACTIVITY bit-is the OR of SLV_ACTIVITY and MST_ACTIVITY bits.\n\n
MST_ACTIVITY: u1 = 0,
/// SLV_ACTIVITY [6:6]
/// Slave FSM Activity Status. When the Slave Finite State Machine (FSM) is not in the IDLE state, this bit is set. - 0: Slave FSM is in IDLE state so the Slave part of DW_apb_i2c is not Active - 1: Slave FSM is not in IDLE state so the Slave part of DW_apb_i2c is Active Reset value: 0x0
SLV_ACTIVITY: u1 = 0,
/// unused [7:31]
_unused7: u1 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// I2C Status Register\n\n
pub const IC_STATUS = Register(IC_STATUS_val).init(base_address + 0x70);

/// IC_ENABLE
const IC_ENABLE_val = packed struct {
/// ENABLE [0:0]
/// Controls whether the DW_apb_i2c is enabled. - 0: Disables DW_apb_i2c (TX and RX FIFOs are held in an erased state) - 1: Enables DW_apb_i2c Software can disable DW_apb_i2c while it is active. However, it is important that care be taken to ensure that DW_apb_i2c is disabled properly. A recommended procedure is described in 'Disabling DW_apb_i2c'.\n\n
ENABLE: u1 = 0,
/// ABORT [1:1]
/// When set, the controller initiates the transfer abort. - 0: ABORT not initiated or ABORT done - 1: ABORT operation in progress The software can abort the I2C transfer in master mode by setting this bit. The software can set this bit only when ENABLE is already set; otherwise, the controller ignores any write to ABORT bit. The software cannot clear the ABORT bit once set. In response to an ABORT, the controller issues a STOP and flushes the Tx FIFO after completing the current transfer, then sets the TX_ABORT interrupt after the abort operation. The ABORT bit is cleared automatically after the abort operation.\n\n
ABORT: u1 = 0,
/// TX_CMD_BLOCK [2:2]
/// In Master mode: - 1'b1: Blocks the transmission of data on I2C bus even if Tx FIFO has data to transmit. - 1'b0: The transmission of data starts on I2C bus automatically, as soon as the first data is available in the Tx FIFO. Note: To block the execution of Master commands, set the TX_CMD_BLOCK bit only when Tx FIFO is empty (IC_STATUS[2]==1) and Master is in Idle state (IC_STATUS[5] == 0). Any further commands put in the Tx FIFO are not executed until TX_CMD_BLOCK bit is unset. Reset value:  IC_TX_CMD_BLOCK_DEFAULT
TX_CMD_BLOCK: u1 = 0,
/// unused [3:31]
_unused3: u5 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// I2C Enable Register
pub const IC_ENABLE = Register(IC_ENABLE_val).init(base_address + 0x6c);

/// IC_CLR_GEN_CALL
const IC_CLR_GEN_CALL_val = packed struct {
/// CLR_GEN_CALL [0:0]
/// Read this register to clear the GEN_CALL interrupt (bit 11) of IC_RAW_INTR_STAT register.\n\n
CLR_GEN_CALL: u1 = 0,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Clear GEN_CALL Interrupt Register
pub const IC_CLR_GEN_CALL = Register(IC_CLR_GEN_CALL_val).init(base_address + 0x68);

/// IC_CLR_START_DET
const IC_CLR_START_DET_val = packed struct {
/// CLR_START_DET [0:0]
/// Read this register to clear the START_DET interrupt (bit 10) of the IC_RAW_INTR_STAT register.\n\n
CLR_START_DET: u1 = 0,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Clear START_DET Interrupt Register
pub const IC_CLR_START_DET = Register(IC_CLR_START_DET_val).init(base_address + 0x64);

/// IC_CLR_STOP_DET
const IC_CLR_STOP_DET_val = packed struct {
/// CLR_STOP_DET [0:0]
/// Read this register to clear the STOP_DET interrupt (bit 9) of the IC_RAW_INTR_STAT register.\n\n
CLR_STOP_DET: u1 = 0,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Clear STOP_DET Interrupt Register
pub const IC_CLR_STOP_DET = Register(IC_CLR_STOP_DET_val).init(base_address + 0x60);

/// IC_CLR_ACTIVITY
const IC_CLR_ACTIVITY_val = packed struct {
/// CLR_ACTIVITY [0:0]
/// Reading this register clears the ACTIVITY interrupt if the I2C is not active anymore. If the I2C module is still active on the bus, the ACTIVITY interrupt bit continues to be set. It is automatically cleared by hardware if the module is disabled and if there is no further activity on the bus. The value read from this register to get status of the ACTIVITY interrupt (bit 8) of the IC_RAW_INTR_STAT register.\n\n
CLR_ACTIVITY: u1 = 0,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Clear ACTIVITY Interrupt Register
pub const IC_CLR_ACTIVITY = Register(IC_CLR_ACTIVITY_val).init(base_address + 0x5c);

/// IC_CLR_RX_DONE
const IC_CLR_RX_DONE_val = packed struct {
/// CLR_RX_DONE [0:0]
/// Read this register to clear the RX_DONE interrupt (bit 7) of the IC_RAW_INTR_STAT register.\n\n
CLR_RX_DONE: u1 = 0,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Clear RX_DONE Interrupt Register
pub const IC_CLR_RX_DONE = Register(IC_CLR_RX_DONE_val).init(base_address + 0x58);

/// IC_CLR_TX_ABRT
const IC_CLR_TX_ABRT_val = packed struct {
/// CLR_TX_ABRT [0:0]
/// Read this register to clear the TX_ABRT interrupt (bit 6) of the IC_RAW_INTR_STAT register, and the IC_TX_ABRT_SOURCE register. This also releases the TX FIFO from the flushed/reset state, allowing more writes to the TX FIFO. Refer to Bit 9 of the IC_TX_ABRT_SOURCE register for an exception to clearing IC_TX_ABRT_SOURCE.\n\n
CLR_TX_ABRT: u1 = 0,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Clear TX_ABRT Interrupt Register
pub const IC_CLR_TX_ABRT = Register(IC_CLR_TX_ABRT_val).init(base_address + 0x54);

/// IC_CLR_RD_REQ
const IC_CLR_RD_REQ_val = packed struct {
/// CLR_RD_REQ [0:0]
/// Read this register to clear the RD_REQ interrupt (bit 5) of the IC_RAW_INTR_STAT register.\n\n
CLR_RD_REQ: u1 = 0,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Clear RD_REQ Interrupt Register
pub const IC_CLR_RD_REQ = Register(IC_CLR_RD_REQ_val).init(base_address + 0x50);

/// IC_CLR_TX_OVER
const IC_CLR_TX_OVER_val = packed struct {
/// CLR_TX_OVER [0:0]
/// Read this register to clear the TX_OVER interrupt (bit 3) of the IC_RAW_INTR_STAT register.\n\n
CLR_TX_OVER: u1 = 0,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Clear TX_OVER Interrupt Register
pub const IC_CLR_TX_OVER = Register(IC_CLR_TX_OVER_val).init(base_address + 0x4c);

/// IC_CLR_RX_OVER
const IC_CLR_RX_OVER_val = packed struct {
/// CLR_RX_OVER [0:0]
/// Read this register to clear the RX_OVER interrupt (bit 1) of the IC_RAW_INTR_STAT register.\n\n
CLR_RX_OVER: u1 = 0,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Clear RX_OVER Interrupt Register
pub const IC_CLR_RX_OVER = Register(IC_CLR_RX_OVER_val).init(base_address + 0x48);

/// IC_CLR_RX_UNDER
const IC_CLR_RX_UNDER_val = packed struct {
/// CLR_RX_UNDER [0:0]
/// Read this register to clear the RX_UNDER interrupt (bit 0) of the IC_RAW_INTR_STAT register.\n\n
CLR_RX_UNDER: u1 = 0,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Clear RX_UNDER Interrupt Register
pub const IC_CLR_RX_UNDER = Register(IC_CLR_RX_UNDER_val).init(base_address + 0x44);

/// IC_CLR_INTR
const IC_CLR_INTR_val = packed struct {
/// CLR_INTR [0:0]
/// Read this register to clear the combined interrupt, all individual interrupts, and the IC_TX_ABRT_SOURCE register. This bit does not clear hardware clearable interrupts but software clearable interrupts. Refer to Bit 9 of the IC_TX_ABRT_SOURCE register for an exception to clearing IC_TX_ABRT_SOURCE.\n\n
CLR_INTR: u1 = 0,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Clear Combined and Individual Interrupt Register
pub const IC_CLR_INTR = Register(IC_CLR_INTR_val).init(base_address + 0x40);

/// IC_TX_TL
const IC_TX_TL_val = packed struct {
/// TX_TL [0:7]
/// Transmit FIFO Threshold Level.\n\n
TX_TL: u8 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// I2C Transmit FIFO Threshold Register
pub const IC_TX_TL = Register(IC_TX_TL_val).init(base_address + 0x3c);

/// IC_RX_TL
const IC_RX_TL_val = packed struct {
/// RX_TL [0:7]
/// Receive FIFO Threshold Level.\n\n
RX_TL: u8 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// I2C Receive FIFO Threshold Register
pub const IC_RX_TL = Register(IC_RX_TL_val).init(base_address + 0x38);

/// IC_RAW_INTR_STAT
const IC_RAW_INTR_STAT_val = packed struct {
/// RX_UNDER [0:0]
/// Set if the processor attempts to read the receive buffer when it is empty by reading from the IC_DATA_CMD register. If the module is disabled (IC_ENABLE[0]=0), this bit keeps its level until the master or slave state machines go into idle, and when ic_en goes to 0, this interrupt is cleared.\n\n
RX_UNDER: u1 = 0,
/// RX_OVER [1:1]
/// Set if the receive buffer is completely filled to IC_RX_BUFFER_DEPTH and an additional byte is received from an external I2C device. The DW_apb_i2c acknowledges this, but any data bytes received after the FIFO is full are lost. If the module is disabled (IC_ENABLE[0]=0), this bit keeps its level until the master or slave state machines go into idle, and when ic_en goes to 0, this interrupt is cleared.\n\n
RX_OVER: u1 = 0,
/// RX_FULL [2:2]
/// Set when the receive buffer reaches or goes above the RX_TL threshold in the IC_RX_TL register. It is automatically cleared by hardware when buffer level goes below the threshold. If the module is disabled (IC_ENABLE[0]=0), the RX FIFO is flushed and held in reset; therefore the RX FIFO is not full. So this bit is cleared once the IC_ENABLE bit 0 is programmed with a 0, regardless of the activity that continues.\n\n
RX_FULL: u1 = 0,
/// TX_OVER [3:3]
/// Set during transmit if the transmit buffer is filled to IC_TX_BUFFER_DEPTH and the processor attempts to issue another I2C command by writing to the IC_DATA_CMD register. When the module is disabled, this bit keeps its level until the master or slave state machines go into idle, and when ic_en goes to 0, this interrupt is cleared.\n\n
TX_OVER: u1 = 0,
/// TX_EMPTY [4:4]
/// The behavior of the TX_EMPTY interrupt status differs based on the TX_EMPTY_CTRL selection in the IC_CON register. - When TX_EMPTY_CTRL = 0: This bit is set to 1 when the transmit buffer is at or below the threshold value set in the IC_TX_TL register. - When TX_EMPTY_CTRL = 1: This bit is set to 1 when the transmit buffer is at or below the threshold value set in the IC_TX_TL register and the transmission of the address/data from the internal shift register for the most recently popped command is completed. It is automatically cleared by hardware when the buffer level goes above the threshold. When IC_ENABLE[0] is set to 0, the TX FIFO is flushed and held in reset. There the TX FIFO looks like it has no data within it, so this bit is set to 1, provided there is activity in the master or slave state machines. When there is no longer any activity, then with ic_en=0, this bit is set to 0.\n\n
TX_EMPTY: u1 = 0,
/// RD_REQ [5:5]
/// This bit is set to 1 when DW_apb_i2c is acting as a slave and another I2C master is attempting to read data from DW_apb_i2c. The DW_apb_i2c holds the I2C bus in a wait state (SCL=0) until this interrupt is serviced, which means that the slave has been addressed by a remote master that is asking for data to be transferred. The processor must respond to this interrupt and then write the requested data to the IC_DATA_CMD register. This bit is set to 0 just after the processor reads the IC_CLR_RD_REQ register.\n\n
RD_REQ: u1 = 0,
/// TX_ABRT [6:6]
/// This bit indicates if DW_apb_i2c, as an I2C transmitter, is unable to complete the intended actions on the contents of the transmit FIFO. This situation can occur both as an I2C master or an I2C slave, and is referred to as a 'transmit abort'. When this bit is set to 1, the IC_TX_ABRT_SOURCE register indicates the reason why the transmit abort takes places.\n\n
TX_ABRT: u1 = 0,
/// RX_DONE [7:7]
/// When the DW_apb_i2c is acting as a slave-transmitter, this bit is set to 1 if the master does not acknowledge a transmitted byte. This occurs on the last byte of the transmission, indicating that the transmission is done.\n\n
RX_DONE: u1 = 0,
/// ACTIVITY [8:8]
/// This bit captures DW_apb_i2c activity and stays set until it is cleared. There are four ways to clear it: - Disabling the DW_apb_i2c - Reading the IC_CLR_ACTIVITY register - Reading the IC_CLR_INTR register - System reset Once this bit is set, it stays set unless one of the four methods is used to clear it. Even if the DW_apb_i2c module is idle, this bit remains set until cleared, indicating that there was activity on the bus.\n\n
ACTIVITY: u1 = 0,
/// STOP_DET [9:9]
/// Indicates whether a STOP condition has occurred on the I2C interface regardless of whether DW_apb_i2c is operating in slave or master mode.\n\n
STOP_DET: u1 = 0,
/// START_DET [10:10]
/// Indicates whether a START or RESTART condition has occurred on the I2C interface regardless of whether DW_apb_i2c is operating in slave or master mode.\n\n
START_DET: u1 = 0,
/// GEN_CALL [11:11]
/// Set only when a General Call address is received and it is acknowledged. It stays set until it is cleared either by disabling DW_apb_i2c or when the CPU reads bit 0 of the IC_CLR_GEN_CALL register. DW_apb_i2c stores the received data in the Rx buffer.\n\n
GEN_CALL: u1 = 0,
/// RESTART_DET [12:12]
/// Indicates whether a RESTART condition has occurred on the I2C interface when DW_apb_i2c is operating in Slave mode and the slave is being addressed. Enabled only when IC_SLV_RESTART_DET_EN=1.\n\n
RESTART_DET: u1 = 0,
/// unused [13:31]
_unused13: u3 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// I2C Raw Interrupt Status Register\n\n
pub const IC_RAW_INTR_STAT = Register(IC_RAW_INTR_STAT_val).init(base_address + 0x34);

/// IC_INTR_MASK
const IC_INTR_MASK_val = packed struct {
/// M_RX_UNDER [0:0]
/// This bit masks the R_RX_UNDER interrupt in IC_INTR_STAT register.\n\n
M_RX_UNDER: u1 = 1,
/// M_RX_OVER [1:1]
/// This bit masks the R_RX_OVER interrupt in IC_INTR_STAT register.\n\n
M_RX_OVER: u1 = 1,
/// M_RX_FULL [2:2]
/// This bit masks the R_RX_FULL interrupt in IC_INTR_STAT register.\n\n
M_RX_FULL: u1 = 1,
/// M_TX_OVER [3:3]
/// This bit masks the R_TX_OVER interrupt in IC_INTR_STAT register.\n\n
M_TX_OVER: u1 = 1,
/// M_TX_EMPTY [4:4]
/// This bit masks the R_TX_EMPTY interrupt in IC_INTR_STAT register.\n\n
M_TX_EMPTY: u1 = 1,
/// M_RD_REQ [5:5]
/// This bit masks the R_RD_REQ interrupt in IC_INTR_STAT register.\n\n
M_RD_REQ: u1 = 1,
/// M_TX_ABRT [6:6]
/// This bit masks the R_TX_ABRT interrupt in IC_INTR_STAT register.\n\n
M_TX_ABRT: u1 = 1,
/// M_RX_DONE [7:7]
/// This bit masks the R_RX_DONE interrupt in IC_INTR_STAT register.\n\n
M_RX_DONE: u1 = 1,
/// M_ACTIVITY [8:8]
/// This bit masks the R_ACTIVITY interrupt in IC_INTR_STAT register.\n\n
M_ACTIVITY: u1 = 0,
/// M_STOP_DET [9:9]
/// This bit masks the R_STOP_DET interrupt in IC_INTR_STAT register.\n\n
M_STOP_DET: u1 = 0,
/// M_START_DET [10:10]
/// This bit masks the R_START_DET interrupt in IC_INTR_STAT register.\n\n
M_START_DET: u1 = 0,
/// M_GEN_CALL [11:11]
/// This bit masks the R_GEN_CALL interrupt in IC_INTR_STAT register.\n\n
M_GEN_CALL: u1 = 1,
/// M_RESTART_DET [12:12]
/// This bit masks the R_RESTART_DET interrupt in IC_INTR_STAT register.\n\n
M_RESTART_DET: u1 = 0,
/// unused [13:31]
_unused13: u3 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// I2C Interrupt Mask Register.\n\n
pub const IC_INTR_MASK = Register(IC_INTR_MASK_val).init(base_address + 0x30);

/// IC_INTR_STAT
const IC_INTR_STAT_val = packed struct {
/// R_RX_UNDER [0:0]
/// See IC_RAW_INTR_STAT for a detailed description of R_RX_UNDER bit.\n\n
R_RX_UNDER: u1 = 0,
/// R_RX_OVER [1:1]
/// See IC_RAW_INTR_STAT for a detailed description of R_RX_OVER bit.\n\n
R_RX_OVER: u1 = 0,
/// R_RX_FULL [2:2]
/// See IC_RAW_INTR_STAT for a detailed description of R_RX_FULL bit.\n\n
R_RX_FULL: u1 = 0,
/// R_TX_OVER [3:3]
/// See IC_RAW_INTR_STAT for a detailed description of R_TX_OVER bit.\n\n
R_TX_OVER: u1 = 0,
/// R_TX_EMPTY [4:4]
/// See IC_RAW_INTR_STAT for a detailed description of R_TX_EMPTY bit.\n\n
R_TX_EMPTY: u1 = 0,
/// R_RD_REQ [5:5]
/// See IC_RAW_INTR_STAT for a detailed description of R_RD_REQ bit.\n\n
R_RD_REQ: u1 = 0,
/// R_TX_ABRT [6:6]
/// See IC_RAW_INTR_STAT for a detailed description of R_TX_ABRT bit.\n\n
R_TX_ABRT: u1 = 0,
/// R_RX_DONE [7:7]
/// See IC_RAW_INTR_STAT for a detailed description of R_RX_DONE bit.\n\n
R_RX_DONE: u1 = 0,
/// R_ACTIVITY [8:8]
/// See IC_RAW_INTR_STAT for a detailed description of R_ACTIVITY bit.\n\n
R_ACTIVITY: u1 = 0,
/// R_STOP_DET [9:9]
/// See IC_RAW_INTR_STAT for a detailed description of R_STOP_DET bit.\n\n
R_STOP_DET: u1 = 0,
/// R_START_DET [10:10]
/// See IC_RAW_INTR_STAT for a detailed description of R_START_DET bit.\n\n
R_START_DET: u1 = 0,
/// R_GEN_CALL [11:11]
/// See IC_RAW_INTR_STAT for a detailed description of R_GEN_CALL bit.\n\n
R_GEN_CALL: u1 = 0,
/// R_RESTART_DET [12:12]
/// See IC_RAW_INTR_STAT for a detailed description of R_RESTART_DET bit.\n\n
R_RESTART_DET: u1 = 0,
/// unused [13:31]
_unused13: u3 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// I2C Interrupt Status Register\n\n
pub const IC_INTR_STAT = Register(IC_INTR_STAT_val).init(base_address + 0x2c);

/// IC_FS_SCL_LCNT
const IC_FS_SCL_LCNT_val = packed struct {
/// IC_FS_SCL_LCNT [0:15]
/// This register must be set before any I2C bus transaction can take place to ensure proper I/O timing. This register sets the SCL clock low period count for fast speed. It is used in high-speed mode to send the Master Code and START BYTE or General CALL. For more information, refer to 'IC_CLK Frequency Configuration'.\n\n
IC_FS_SCL_LCNT: u16 = 13,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Fast Mode or Fast Mode Plus I2C Clock SCL Low Count Register
pub const IC_FS_SCL_LCNT = Register(IC_FS_SCL_LCNT_val).init(base_address + 0x20);

/// IC_FS_SCL_HCNT
const IC_FS_SCL_HCNT_val = packed struct {
/// IC_FS_SCL_HCNT [0:15]
/// This register must be set before any I2C bus transaction can take place to ensure proper I/O timing. This register sets the SCL clock high-period count for fast mode or fast mode plus. It is used in high-speed mode to send the Master Code and START BYTE or General CALL. For more information, refer to 'IC_CLK Frequency Configuration'.\n\n
IC_FS_SCL_HCNT: u16 = 6,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Fast Mode or Fast Mode Plus I2C Clock SCL High Count Register
pub const IC_FS_SCL_HCNT = Register(IC_FS_SCL_HCNT_val).init(base_address + 0x1c);

/// IC_SS_SCL_LCNT
const IC_SS_SCL_LCNT_val = packed struct {
/// IC_SS_SCL_LCNT [0:15]
/// This register must be set before any I2C bus transaction can take place to ensure proper I/O timing. This register sets the SCL clock low period count for standard speed. For more information, refer to 'IC_CLK Frequency Configuration'\n\n
IC_SS_SCL_LCNT: u16 = 47,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Standard Speed I2C Clock SCL Low Count Register
pub const IC_SS_SCL_LCNT = Register(IC_SS_SCL_LCNT_val).init(base_address + 0x18);

/// IC_SS_SCL_HCNT
const IC_SS_SCL_HCNT_val = packed struct {
/// IC_SS_SCL_HCNT [0:15]
/// This register must be set before any I2C bus transaction can take place to ensure proper I/O timing. This register sets the SCL clock high-period count for standard speed. For more information, refer to 'IC_CLK Frequency Configuration'.\n\n
IC_SS_SCL_HCNT: u16 = 40,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Standard Speed I2C Clock SCL High Count Register
pub const IC_SS_SCL_HCNT = Register(IC_SS_SCL_HCNT_val).init(base_address + 0x14);

/// IC_DATA_CMD
const IC_DATA_CMD_val = packed struct {
/// DAT [0:7]
/// This register contains the data to be transmitted or received on the I2C bus. If you are writing to this register and want to perform a read, bits 7:0 (DAT) are ignored by the DW_apb_i2c. However, when you read this register, these bits return the value of data received on the DW_apb_i2c interface.\n\n
DAT: u8 = 0,
/// CMD [8:8]
/// This bit controls whether a read or a write is performed. This bit does not control the direction when the DW_apb_i2con acts as a slave. It controls only the direction when it acts as a master.\n\n
CMD: u1 = 0,
/// STOP [9:9]
/// This bit controls whether a STOP is issued after the byte is sent or received.\n\n
STOP: u1 = 0,
/// RESTART [10:10]
/// This bit controls whether a RESTART is issued before the byte is sent or received.\n\n
RESTART: u1 = 0,
/// FIRST_DATA_BYTE [11:11]
/// Indicates the first data byte received after the address phase for receive transfer in Master receiver or Slave receiver mode.\n\n
FIRST_DATA_BYTE: u1 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// I2C Rx/Tx Data Buffer and Command Register; this is the register the CPU writes to when filling the TX FIFO and the CPU reads from when retrieving bytes from RX FIFO.\n\n
pub const IC_DATA_CMD = Register(IC_DATA_CMD_val).init(base_address + 0x10);

/// IC_SAR
const IC_SAR_val = packed struct {
/// IC_SAR [0:9]
/// The IC_SAR holds the slave address when the I2C is operating as a slave. For 7-bit addressing, only IC_SAR[6:0] is used.\n\n
IC_SAR: u10 = 85,
/// unused [10:31]
_unused10: u6 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// I2C Slave Address Register
pub const IC_SAR = Register(IC_SAR_val).init(base_address + 0x8);

/// IC_TAR
const IC_TAR_val = packed struct {
/// IC_TAR [0:9]
/// This is the target address for any master transaction. When transmitting a General Call, these bits are ignored. To generate a START BYTE, the CPU needs to write only once into these bits.\n\n
IC_TAR: u10 = 85,
/// GC_OR_START [10:10]
/// If bit 11 (SPECIAL) is set to 1 and bit 13(Device-ID) is set to 0, then this bit indicates whether a General Call or START byte command is to be performed by the DW_apb_i2c. - 0: General Call Address - after issuing a General Call, only writes may be performed. Attempting to issue a read command results in setting bit 6 (TX_ABRT) of the IC_RAW_INTR_STAT register. The DW_apb_i2c remains in General Call mode until the SPECIAL bit value (bit 11) is cleared. - 1: START BYTE Reset value: 0x0
GC_OR_START: u1 = 0,
/// SPECIAL [11:11]
/// This bit indicates whether software performs a Device-ID or General Call or START BYTE command. - 0: ignore bit 10 GC_OR_START and use IC_TAR normally - 1: perform special I2C command as specified in Device_ID or GC_OR_START bit Reset value: 0x0
SPECIAL: u1 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// I2C Target Address Register\n\n
pub const IC_TAR = Register(IC_TAR_val).init(base_address + 0x4);

/// IC_CON
const IC_CON_val = packed struct {
/// MASTER_MODE [0:0]
/// This bit controls whether the DW_apb_i2c master is enabled.\n\n
MASTER_MODE: u1 = 1,
/// SPEED [1:2]
/// These bits control at which speed the DW_apb_i2c operates; its setting is relevant only if one is operating the DW_apb_i2c in master mode. Hardware protects against illegal values being programmed by software. These bits must be programmed appropriately for slave mode also, as it is used to capture correct value of spike filter as per the speed mode.\n\n
SPEED: u2 = 2,
/// IC_10BITADDR_SLAVE [3:3]
/// When acting as a slave, this bit controls whether the DW_apb_i2c responds to 7- or 10-bit addresses. - 0: 7-bit addressing. The DW_apb_i2c ignores transactions that involve 10-bit addressing; for 7-bit addressing, only the lower 7 bits of the IC_SAR register are compared. - 1: 10-bit addressing. The DW_apb_i2c responds to only 10-bit addressing transfers that match the full 10 bits of the IC_SAR register.
IC_10BITADDR_SLAVE: u1 = 0,
/// IC_10BITADDR_MASTER [4:4]
/// Controls whether the DW_apb_i2c starts its transfers in 7- or 10-bit addressing mode when acting as a master. - 0: 7-bit addressing - 1: 10-bit addressing
IC_10BITADDR_MASTER: u1 = 0,
/// IC_RESTART_EN [5:5]
/// Determines whether RESTART conditions may be sent when acting as a master. Some older slaves do not support handling RESTART conditions; however, RESTART conditions are used in several DW_apb_i2c operations. When RESTART is disabled, the master is prohibited from performing the following functions: - Sending a START BYTE - Performing any high-speed mode operation - High-speed mode operation - Performing direction changes in combined format mode - Performing a read operation with a 10-bit address By replacing RESTART condition followed by a STOP and a subsequent START condition, split operations are broken down into multiple DW_apb_i2c transfers. If the above operations are performed, it will result in setting bit 6 (TX_ABRT) of the IC_RAW_INTR_STAT register.\n\n
IC_RESTART_EN: u1 = 1,
/// IC_SLAVE_DISABLE [6:6]
/// This bit controls whether I2C has its slave disabled, which means once the presetn signal is applied, then this bit is set and the slave is disabled.\n\n
IC_SLAVE_DISABLE: u1 = 1,
/// STOP_DET_IFADDRESSED [7:7]
/// In slave mode: - 1'b1:  issues the STOP_DET interrupt only when it is addressed. - 1'b0:  issues the STOP_DET irrespective of whether it's addressed or not. Reset value: 0x0\n\n
STOP_DET_IFADDRESSED: u1 = 0,
/// TX_EMPTY_CTRL [8:8]
/// This bit controls the generation of the TX_EMPTY interrupt, as described in the IC_RAW_INTR_STAT register.\n\n
TX_EMPTY_CTRL: u1 = 0,
/// RX_FIFO_FULL_HLD_CTRL [9:9]
/// This bit controls whether DW_apb_i2c should hold the bus when the Rx FIFO is physically full to its RX_BUFFER_DEPTH, as described in the IC_RX_FULL_HLD_BUS_EN parameter.\n\n
RX_FIFO_FULL_HLD_CTRL: u1 = 0,
/// STOP_DET_IF_MASTER_ACTIVE [10:10]
/// Master issues the STOP_DET interrupt irrespective of whether master is active or not
STOP_DET_IF_MASTER_ACTIVE: u1 = 0,
/// unused [11:31]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// I2C Control Register. This register can be written only when the DW_apb_i2c is disabled, which corresponds to the IC_ENABLE[0] register being set to 0. Writes at other times have no effect.\n\n
pub const IC_CON = Register(IC_CON_val).init(base_address + 0x0);
};

/// Control and data interface to SAR ADC
pub const ADC = struct {

const base_address = 0x4004c000;
/// INTS
const INTS_val = packed struct {
/// FIFO [0:0]
/// Triggered when the sample FIFO reaches a certain level.\n
FIFO: u1 = 0,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Interrupt status after masking &amp; forcing
pub const INTS = Register(INTS_val).init(base_address + 0x20);

/// INTF
const INTF_val = packed struct {
/// FIFO [0:0]
/// Triggered when the sample FIFO reaches a certain level.\n
FIFO: u1 = 0,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Interrupt Force
pub const INTF = Register(INTF_val).init(base_address + 0x1c);

/// INTE
const INTE_val = packed struct {
/// FIFO [0:0]
/// Triggered when the sample FIFO reaches a certain level.\n
FIFO: u1 = 0,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Interrupt Enable
pub const INTE = Register(INTE_val).init(base_address + 0x18);

/// INTR
const INTR_val = packed struct {
/// FIFO [0:0]
/// Triggered when the sample FIFO reaches a certain level.\n
FIFO: u1 = 0,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Raw Interrupts
pub const INTR = Register(INTR_val).init(base_address + 0x14);

/// DIV
const DIV_val = packed struct {
/// FRAC [0:7]
/// Fractional part of clock divisor. First-order delta-sigma.
FRAC: u8 = 0,
/// INT [8:23]
/// Integer part of clock divisor.
INT: u16 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// Clock divider. If non-zero, CS_START_MANY will start conversions\n
pub const DIV = Register(DIV_val).init(base_address + 0x10);

/// FIFO
const FIFO_val = packed struct {
/// VAL [0:11]
/// No description
VAL: u12 = 0,
/// unused [12:14]
_unused12: u3 = 0,
/// ERR [15:15]
/// 1 if this particular sample experienced a conversion error. Remains in the same location if the sample is shifted.
ERR: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Conversion result FIFO
pub const FIFO = Register(FIFO_val).init(base_address + 0xc);

/// FCS
const FCS_val = packed struct {
/// EN [0:0]
/// If 1: write result to the FIFO after each conversion.
EN: u1 = 0,
/// SHIFT [1:1]
/// If 1: FIFO results are right-shifted to be one byte in size. Enables DMA to byte buffers.
SHIFT: u1 = 0,
/// ERR [2:2]
/// If 1: conversion error bit appears in the FIFO alongside the result
ERR: u1 = 0,
/// DREQ_EN [3:3]
/// If 1: assert DMA requests when FIFO contains data
DREQ_EN: u1 = 0,
/// unused [4:7]
_unused4: u4 = 0,
/// EMPTY [8:8]
/// No description
EMPTY: u1 = 0,
/// FULL [9:9]
/// No description
FULL: u1 = 0,
/// UNDER [10:10]
/// 1 if the FIFO has been underflowed. Write 1 to clear.
UNDER: u1 = 0,
/// OVER [11:11]
/// 1 if the FIFO has been overflowed. Write 1 to clear.
OVER: u1 = 0,
/// unused [12:15]
_unused12: u4 = 0,
/// LEVEL [16:19]
/// The number of conversion results currently waiting in the FIFO
LEVEL: u4 = 0,
/// unused [20:23]
_unused20: u4 = 0,
/// THRESH [24:27]
/// DREQ/IRQ asserted when level &gt;= threshold
THRESH: u4 = 0,
/// unused [28:31]
_unused28: u4 = 0,
};
/// FIFO control and status
pub const FCS = Register(FCS_val).init(base_address + 0x8);

/// RESULT
const RESULT_val = packed struct {
/// RESULT [0:11]
/// No description
RESULT: u12 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Result of most recent ADC conversion
pub const RESULT = Register(RESULT_val).init(base_address + 0x4);

/// CS
const CS_val = packed struct {
/// EN [0:0]
/// Power on ADC and enable its clock.\n
EN: u1 = 0,
/// TS_EN [1:1]
/// Power on temperature sensor. 1 - enabled. 0 - disabled.
TS_EN: u1 = 0,
/// START_ONCE [2:2]
/// Start a single conversion. Self-clearing. Ignored if start_many is asserted.
START_ONCE: u1 = 0,
/// START_MANY [3:3]
/// Continuously perform conversions whilst this bit is 1. A new conversion will start immediately after the previous finishes.
START_MANY: u1 = 0,
/// unused [4:7]
_unused4: u4 = 0,
/// READY [8:8]
/// 1 if the ADC is ready to start a new conversion. Implies any previous conversion has completed.\n
READY: u1 = 0,
/// ERR [9:9]
/// The most recent ADC conversion encountered an error; result is undefined or noisy.
ERR: u1 = 0,
/// ERR_STICKY [10:10]
/// Some past ADC conversion encountered an error. Write 1 to clear.
ERR_STICKY: u1 = 0,
/// unused [11:11]
_unused11: u1 = 0,
/// AINSEL [12:14]
/// Select analog mux input. Updated automatically in round-robin mode.
AINSEL: u3 = 0,
/// unused [15:15]
_unused15: u1 = 0,
/// RROBIN [16:20]
/// Round-robin sampling. 1 bit per channel. Set all bits to 0 to disable.\n
RROBIN: u5 = 0,
/// unused [21:31]
_unused21: u3 = 0,
_unused24: u8 = 0,
};
/// ADC Control and Status
pub const CS = Register(CS_val).init(base_address + 0x0);
};

/// Simple PWM
pub const PWM = struct {

const base_address = 0x40050000;
/// INTS
const INTS_val = packed struct {
/// CH0 [0:0]
/// No description
CH0: u1 = 0,
/// CH1 [1:1]
/// No description
CH1: u1 = 0,
/// CH2 [2:2]
/// No description
CH2: u1 = 0,
/// CH3 [3:3]
/// No description
CH3: u1 = 0,
/// CH4 [4:4]
/// No description
CH4: u1 = 0,
/// CH5 [5:5]
/// No description
CH5: u1 = 0,
/// CH6 [6:6]
/// No description
CH6: u1 = 0,
/// CH7 [7:7]
/// No description
CH7: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Interrupt status after masking &amp; forcing
pub const INTS = Register(INTS_val).init(base_address + 0xb0);

/// INTF
const INTF_val = packed struct {
/// CH0 [0:0]
/// No description
CH0: u1 = 0,
/// CH1 [1:1]
/// No description
CH1: u1 = 0,
/// CH2 [2:2]
/// No description
CH2: u1 = 0,
/// CH3 [3:3]
/// No description
CH3: u1 = 0,
/// CH4 [4:4]
/// No description
CH4: u1 = 0,
/// CH5 [5:5]
/// No description
CH5: u1 = 0,
/// CH6 [6:6]
/// No description
CH6: u1 = 0,
/// CH7 [7:7]
/// No description
CH7: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Interrupt Force
pub const INTF = Register(INTF_val).init(base_address + 0xac);

/// INTE
const INTE_val = packed struct {
/// CH0 [0:0]
/// No description
CH0: u1 = 0,
/// CH1 [1:1]
/// No description
CH1: u1 = 0,
/// CH2 [2:2]
/// No description
CH2: u1 = 0,
/// CH3 [3:3]
/// No description
CH3: u1 = 0,
/// CH4 [4:4]
/// No description
CH4: u1 = 0,
/// CH5 [5:5]
/// No description
CH5: u1 = 0,
/// CH6 [6:6]
/// No description
CH6: u1 = 0,
/// CH7 [7:7]
/// No description
CH7: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Interrupt Enable
pub const INTE = Register(INTE_val).init(base_address + 0xa8);

/// INTR
const INTR_val = packed struct {
/// CH0 [0:0]
/// No description
CH0: u1 = 0,
/// CH1 [1:1]
/// No description
CH1: u1 = 0,
/// CH2 [2:2]
/// No description
CH2: u1 = 0,
/// CH3 [3:3]
/// No description
CH3: u1 = 0,
/// CH4 [4:4]
/// No description
CH4: u1 = 0,
/// CH5 [5:5]
/// No description
CH5: u1 = 0,
/// CH6 [6:6]
/// No description
CH6: u1 = 0,
/// CH7 [7:7]
/// No description
CH7: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Raw Interrupts
pub const INTR = Register(INTR_val).init(base_address + 0xa4);

/// EN
const EN_val = packed struct {
/// CH0 [0:0]
/// No description
CH0: u1 = 0,
/// CH1 [1:1]
/// No description
CH1: u1 = 0,
/// CH2 [2:2]
/// No description
CH2: u1 = 0,
/// CH3 [3:3]
/// No description
CH3: u1 = 0,
/// CH4 [4:4]
/// No description
CH4: u1 = 0,
/// CH5 [5:5]
/// No description
CH5: u1 = 0,
/// CH6 [6:6]
/// No description
CH6: u1 = 0,
/// CH7 [7:7]
/// No description
CH7: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// This register aliases the CSR_EN bits for all channels.\n
pub const EN = Register(EN_val).init(base_address + 0xa0);

/// CH7_TOP
const CH7_TOP_val = packed struct {
/// CH7_TOP [0:15]
/// No description
CH7_TOP: u16 = 65535,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Counter wrap value
pub const CH7_TOP = Register(CH7_TOP_val).init(base_address + 0x9c);

/// CH7_CC
const CH7_CC_val = packed struct {
/// A [0:15]
/// No description
A: u16 = 0,
/// B [16:31]
/// No description
B: u16 = 0,
};
/// Counter compare values
pub const CH7_CC = Register(CH7_CC_val).init(base_address + 0x98);

/// CH7_CTR
const CH7_CTR_val = packed struct {
/// CH7_CTR [0:15]
/// No description
CH7_CTR: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Direct access to the PWM counter
pub const CH7_CTR = Register(CH7_CTR_val).init(base_address + 0x94);

/// CH7_DIV
const CH7_DIV_val = packed struct {
/// FRAC [0:3]
/// No description
FRAC: u4 = 0,
/// INT [4:11]
/// No description
INT: u8 = 1,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// INT and FRAC form a fixed-point fractional number.\n
pub const CH7_DIV = Register(CH7_DIV_val).init(base_address + 0x90);

/// CH7_CSR
const CH7_CSR_val = packed struct {
/// EN [0:0]
/// Enable the PWM channel.
EN: u1 = 0,
/// PH_CORRECT [1:1]
/// 1: Enable phase-correct modulation. 0: Trailing-edge
PH_CORRECT: u1 = 0,
/// A_INV [2:2]
/// Invert output A
A_INV: u1 = 0,
/// B_INV [3:3]
/// Invert output B
B_INV: u1 = 0,
/// DIVMODE [4:5]
/// No description
DIVMODE: u2 = 0,
/// PH_RET [6:6]
/// Retard the phase of the counter by 1 count, while it is running.\n
PH_RET: u1 = 0,
/// PH_ADV [7:7]
/// Advance the phase of the counter by 1 count, while it is running.\n
PH_ADV: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Control and status register
pub const CH7_CSR = Register(CH7_CSR_val).init(base_address + 0x8c);

/// CH6_TOP
const CH6_TOP_val = packed struct {
/// CH6_TOP [0:15]
/// No description
CH6_TOP: u16 = 65535,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Counter wrap value
pub const CH6_TOP = Register(CH6_TOP_val).init(base_address + 0x88);

/// CH6_CC
const CH6_CC_val = packed struct {
/// A [0:15]
/// No description
A: u16 = 0,
/// B [16:31]
/// No description
B: u16 = 0,
};
/// Counter compare values
pub const CH6_CC = Register(CH6_CC_val).init(base_address + 0x84);

/// CH6_CTR
const CH6_CTR_val = packed struct {
/// CH6_CTR [0:15]
/// No description
CH6_CTR: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Direct access to the PWM counter
pub const CH6_CTR = Register(CH6_CTR_val).init(base_address + 0x80);

/// CH6_DIV
const CH6_DIV_val = packed struct {
/// FRAC [0:3]
/// No description
FRAC: u4 = 0,
/// INT [4:11]
/// No description
INT: u8 = 1,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// INT and FRAC form a fixed-point fractional number.\n
pub const CH6_DIV = Register(CH6_DIV_val).init(base_address + 0x7c);

/// CH6_CSR
const CH6_CSR_val = packed struct {
/// EN [0:0]
/// Enable the PWM channel.
EN: u1 = 0,
/// PH_CORRECT [1:1]
/// 1: Enable phase-correct modulation. 0: Trailing-edge
PH_CORRECT: u1 = 0,
/// A_INV [2:2]
/// Invert output A
A_INV: u1 = 0,
/// B_INV [3:3]
/// Invert output B
B_INV: u1 = 0,
/// DIVMODE [4:5]
/// No description
DIVMODE: u2 = 0,
/// PH_RET [6:6]
/// Retard the phase of the counter by 1 count, while it is running.\n
PH_RET: u1 = 0,
/// PH_ADV [7:7]
/// Advance the phase of the counter by 1 count, while it is running.\n
PH_ADV: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Control and status register
pub const CH6_CSR = Register(CH6_CSR_val).init(base_address + 0x78);

/// CH5_TOP
const CH5_TOP_val = packed struct {
/// CH5_TOP [0:15]
/// No description
CH5_TOP: u16 = 65535,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Counter wrap value
pub const CH5_TOP = Register(CH5_TOP_val).init(base_address + 0x74);

/// CH5_CC
const CH5_CC_val = packed struct {
/// A [0:15]
/// No description
A: u16 = 0,
/// B [16:31]
/// No description
B: u16 = 0,
};
/// Counter compare values
pub const CH5_CC = Register(CH5_CC_val).init(base_address + 0x70);

/// CH5_CTR
const CH5_CTR_val = packed struct {
/// CH5_CTR [0:15]
/// No description
CH5_CTR: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Direct access to the PWM counter
pub const CH5_CTR = Register(CH5_CTR_val).init(base_address + 0x6c);

/// CH5_DIV
const CH5_DIV_val = packed struct {
/// FRAC [0:3]
/// No description
FRAC: u4 = 0,
/// INT [4:11]
/// No description
INT: u8 = 1,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// INT and FRAC form a fixed-point fractional number.\n
pub const CH5_DIV = Register(CH5_DIV_val).init(base_address + 0x68);

/// CH5_CSR
const CH5_CSR_val = packed struct {
/// EN [0:0]
/// Enable the PWM channel.
EN: u1 = 0,
/// PH_CORRECT [1:1]
/// 1: Enable phase-correct modulation. 0: Trailing-edge
PH_CORRECT: u1 = 0,
/// A_INV [2:2]
/// Invert output A
A_INV: u1 = 0,
/// B_INV [3:3]
/// Invert output B
B_INV: u1 = 0,
/// DIVMODE [4:5]
/// No description
DIVMODE: u2 = 0,
/// PH_RET [6:6]
/// Retard the phase of the counter by 1 count, while it is running.\n
PH_RET: u1 = 0,
/// PH_ADV [7:7]
/// Advance the phase of the counter by 1 count, while it is running.\n
PH_ADV: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Control and status register
pub const CH5_CSR = Register(CH5_CSR_val).init(base_address + 0x64);

/// CH4_TOP
const CH4_TOP_val = packed struct {
/// CH4_TOP [0:15]
/// No description
CH4_TOP: u16 = 65535,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Counter wrap value
pub const CH4_TOP = Register(CH4_TOP_val).init(base_address + 0x60);

/// CH4_CC
const CH4_CC_val = packed struct {
/// A [0:15]
/// No description
A: u16 = 0,
/// B [16:31]
/// No description
B: u16 = 0,
};
/// Counter compare values
pub const CH4_CC = Register(CH4_CC_val).init(base_address + 0x5c);

/// CH4_CTR
const CH4_CTR_val = packed struct {
/// CH4_CTR [0:15]
/// No description
CH4_CTR: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Direct access to the PWM counter
pub const CH4_CTR = Register(CH4_CTR_val).init(base_address + 0x58);

/// CH4_DIV
const CH4_DIV_val = packed struct {
/// FRAC [0:3]
/// No description
FRAC: u4 = 0,
/// INT [4:11]
/// No description
INT: u8 = 1,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// INT and FRAC form a fixed-point fractional number.\n
pub const CH4_DIV = Register(CH4_DIV_val).init(base_address + 0x54);

/// CH4_CSR
const CH4_CSR_val = packed struct {
/// EN [0:0]
/// Enable the PWM channel.
EN: u1 = 0,
/// PH_CORRECT [1:1]
/// 1: Enable phase-correct modulation. 0: Trailing-edge
PH_CORRECT: u1 = 0,
/// A_INV [2:2]
/// Invert output A
A_INV: u1 = 0,
/// B_INV [3:3]
/// Invert output B
B_INV: u1 = 0,
/// DIVMODE [4:5]
/// No description
DIVMODE: u2 = 0,
/// PH_RET [6:6]
/// Retard the phase of the counter by 1 count, while it is running.\n
PH_RET: u1 = 0,
/// PH_ADV [7:7]
/// Advance the phase of the counter by 1 count, while it is running.\n
PH_ADV: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Control and status register
pub const CH4_CSR = Register(CH4_CSR_val).init(base_address + 0x50);

/// CH3_TOP
const CH3_TOP_val = packed struct {
/// CH3_TOP [0:15]
/// No description
CH3_TOP: u16 = 65535,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Counter wrap value
pub const CH3_TOP = Register(CH3_TOP_val).init(base_address + 0x4c);

/// CH3_CC
const CH3_CC_val = packed struct {
/// A [0:15]
/// No description
A: u16 = 0,
/// B [16:31]
/// No description
B: u16 = 0,
};
/// Counter compare values
pub const CH3_CC = Register(CH3_CC_val).init(base_address + 0x48);

/// CH3_CTR
const CH3_CTR_val = packed struct {
/// CH3_CTR [0:15]
/// No description
CH3_CTR: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Direct access to the PWM counter
pub const CH3_CTR = Register(CH3_CTR_val).init(base_address + 0x44);

/// CH3_DIV
const CH3_DIV_val = packed struct {
/// FRAC [0:3]
/// No description
FRAC: u4 = 0,
/// INT [4:11]
/// No description
INT: u8 = 1,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// INT and FRAC form a fixed-point fractional number.\n
pub const CH3_DIV = Register(CH3_DIV_val).init(base_address + 0x40);

/// CH3_CSR
const CH3_CSR_val = packed struct {
/// EN [0:0]
/// Enable the PWM channel.
EN: u1 = 0,
/// PH_CORRECT [1:1]
/// 1: Enable phase-correct modulation. 0: Trailing-edge
PH_CORRECT: u1 = 0,
/// A_INV [2:2]
/// Invert output A
A_INV: u1 = 0,
/// B_INV [3:3]
/// Invert output B
B_INV: u1 = 0,
/// DIVMODE [4:5]
/// No description
DIVMODE: u2 = 0,
/// PH_RET [6:6]
/// Retard the phase of the counter by 1 count, while it is running.\n
PH_RET: u1 = 0,
/// PH_ADV [7:7]
/// Advance the phase of the counter by 1 count, while it is running.\n
PH_ADV: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Control and status register
pub const CH3_CSR = Register(CH3_CSR_val).init(base_address + 0x3c);

/// CH2_TOP
const CH2_TOP_val = packed struct {
/// CH2_TOP [0:15]
/// No description
CH2_TOP: u16 = 65535,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Counter wrap value
pub const CH2_TOP = Register(CH2_TOP_val).init(base_address + 0x38);

/// CH2_CC
const CH2_CC_val = packed struct {
/// A [0:15]
/// No description
A: u16 = 0,
/// B [16:31]
/// No description
B: u16 = 0,
};
/// Counter compare values
pub const CH2_CC = Register(CH2_CC_val).init(base_address + 0x34);

/// CH2_CTR
const CH2_CTR_val = packed struct {
/// CH2_CTR [0:15]
/// No description
CH2_CTR: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Direct access to the PWM counter
pub const CH2_CTR = Register(CH2_CTR_val).init(base_address + 0x30);

/// CH2_DIV
const CH2_DIV_val = packed struct {
/// FRAC [0:3]
/// No description
FRAC: u4 = 0,
/// INT [4:11]
/// No description
INT: u8 = 1,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// INT and FRAC form a fixed-point fractional number.\n
pub const CH2_DIV = Register(CH2_DIV_val).init(base_address + 0x2c);

/// CH2_CSR
const CH2_CSR_val = packed struct {
/// EN [0:0]
/// Enable the PWM channel.
EN: u1 = 0,
/// PH_CORRECT [1:1]
/// 1: Enable phase-correct modulation. 0: Trailing-edge
PH_CORRECT: u1 = 0,
/// A_INV [2:2]
/// Invert output A
A_INV: u1 = 0,
/// B_INV [3:3]
/// Invert output B
B_INV: u1 = 0,
/// DIVMODE [4:5]
/// No description
DIVMODE: u2 = 0,
/// PH_RET [6:6]
/// Retard the phase of the counter by 1 count, while it is running.\n
PH_RET: u1 = 0,
/// PH_ADV [7:7]
/// Advance the phase of the counter by 1 count, while it is running.\n
PH_ADV: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Control and status register
pub const CH2_CSR = Register(CH2_CSR_val).init(base_address + 0x28);

/// CH1_TOP
const CH1_TOP_val = packed struct {
/// CH1_TOP [0:15]
/// No description
CH1_TOP: u16 = 65535,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Counter wrap value
pub const CH1_TOP = Register(CH1_TOP_val).init(base_address + 0x24);

/// CH1_CC
const CH1_CC_val = packed struct {
/// A [0:15]
/// No description
A: u16 = 0,
/// B [16:31]
/// No description
B: u16 = 0,
};
/// Counter compare values
pub const CH1_CC = Register(CH1_CC_val).init(base_address + 0x20);

/// CH1_CTR
const CH1_CTR_val = packed struct {
/// CH1_CTR [0:15]
/// No description
CH1_CTR: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Direct access to the PWM counter
pub const CH1_CTR = Register(CH1_CTR_val).init(base_address + 0x1c);

/// CH1_DIV
const CH1_DIV_val = packed struct {
/// FRAC [0:3]
/// No description
FRAC: u4 = 0,
/// INT [4:11]
/// No description
INT: u8 = 1,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// INT and FRAC form a fixed-point fractional number.\n
pub const CH1_DIV = Register(CH1_DIV_val).init(base_address + 0x18);

/// CH1_CSR
const CH1_CSR_val = packed struct {
/// EN [0:0]
/// Enable the PWM channel.
EN: u1 = 0,
/// PH_CORRECT [1:1]
/// 1: Enable phase-correct modulation. 0: Trailing-edge
PH_CORRECT: u1 = 0,
/// A_INV [2:2]
/// Invert output A
A_INV: u1 = 0,
/// B_INV [3:3]
/// Invert output B
B_INV: u1 = 0,
/// DIVMODE [4:5]
/// No description
DIVMODE: u2 = 0,
/// PH_RET [6:6]
/// Retard the phase of the counter by 1 count, while it is running.\n
PH_RET: u1 = 0,
/// PH_ADV [7:7]
/// Advance the phase of the counter by 1 count, while it is running.\n
PH_ADV: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Control and status register
pub const CH1_CSR = Register(CH1_CSR_val).init(base_address + 0x14);

/// CH0_TOP
const CH0_TOP_val = packed struct {
/// CH0_TOP [0:15]
/// No description
CH0_TOP: u16 = 65535,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Counter wrap value
pub const CH0_TOP = Register(CH0_TOP_val).init(base_address + 0x10);

/// CH0_CC
const CH0_CC_val = packed struct {
/// A [0:15]
/// No description
A: u16 = 0,
/// B [16:31]
/// No description
B: u16 = 0,
};
/// Counter compare values
pub const CH0_CC = Register(CH0_CC_val).init(base_address + 0xc);

/// CH0_CTR
const CH0_CTR_val = packed struct {
/// CH0_CTR [0:15]
/// No description
CH0_CTR: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Direct access to the PWM counter
pub const CH0_CTR = Register(CH0_CTR_val).init(base_address + 0x8);

/// CH0_DIV
const CH0_DIV_val = packed struct {
/// FRAC [0:3]
/// No description
FRAC: u4 = 0,
/// INT [4:11]
/// No description
INT: u8 = 1,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// INT and FRAC form a fixed-point fractional number.\n
pub const CH0_DIV = Register(CH0_DIV_val).init(base_address + 0x4);

/// CH0_CSR
const CH0_CSR_val = packed struct {
/// EN [0:0]
/// Enable the PWM channel.
EN: u1 = 0,
/// PH_CORRECT [1:1]
/// 1: Enable phase-correct modulation. 0: Trailing-edge
PH_CORRECT: u1 = 0,
/// A_INV [2:2]
/// Invert output A
A_INV: u1 = 0,
/// B_INV [3:3]
/// Invert output B
B_INV: u1 = 0,
/// DIVMODE [4:5]
/// No description
DIVMODE: u2 = 0,
/// PH_RET [6:6]
/// Retard the phase of the counter by 1 count, while it is running.\n
PH_RET: u1 = 0,
/// PH_ADV [7:7]
/// Advance the phase of the counter by 1 count, while it is running.\n
PH_ADV: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Control and status register
pub const CH0_CSR = Register(CH0_CSR_val).init(base_address + 0x0);
};

/// Controls time and alarms\n
pub const TIMER = struct {

const base_address = 0x40054000;
/// INTS
const INTS_val = packed struct {
/// ALARM_0 [0:0]
/// No description
ALARM_0: u1 = 0,
/// ALARM_1 [1:1]
/// No description
ALARM_1: u1 = 0,
/// ALARM_2 [2:2]
/// No description
ALARM_2: u1 = 0,
/// ALARM_3 [3:3]
/// No description
ALARM_3: u1 = 0,
/// unused [4:31]
_unused4: u4 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Interrupt status after masking &amp; forcing
pub const INTS = Register(INTS_val).init(base_address + 0x40);

/// INTF
const INTF_val = packed struct {
/// ALARM_0 [0:0]
/// No description
ALARM_0: u1 = 0,
/// ALARM_1 [1:1]
/// No description
ALARM_1: u1 = 0,
/// ALARM_2 [2:2]
/// No description
ALARM_2: u1 = 0,
/// ALARM_3 [3:3]
/// No description
ALARM_3: u1 = 0,
/// unused [4:31]
_unused4: u4 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Interrupt Force
pub const INTF = Register(INTF_val).init(base_address + 0x3c);

/// INTE
const INTE_val = packed struct {
/// ALARM_0 [0:0]
/// No description
ALARM_0: u1 = 0,
/// ALARM_1 [1:1]
/// No description
ALARM_1: u1 = 0,
/// ALARM_2 [2:2]
/// No description
ALARM_2: u1 = 0,
/// ALARM_3 [3:3]
/// No description
ALARM_3: u1 = 0,
/// unused [4:31]
_unused4: u4 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Interrupt Enable
pub const INTE = Register(INTE_val).init(base_address + 0x38);

/// INTR
const INTR_val = packed struct {
/// ALARM_0 [0:0]
/// No description
ALARM_0: u1 = 0,
/// ALARM_1 [1:1]
/// No description
ALARM_1: u1 = 0,
/// ALARM_2 [2:2]
/// No description
ALARM_2: u1 = 0,
/// ALARM_3 [3:3]
/// No description
ALARM_3: u1 = 0,
/// unused [4:31]
_unused4: u4 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Raw Interrupts
pub const INTR = Register(INTR_val).init(base_address + 0x34);

/// PAUSE
const PAUSE_val = packed struct {
/// PAUSE [0:0]
/// No description
PAUSE: u1 = 0,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Set high to pause the timer
pub const PAUSE = Register(PAUSE_val).init(base_address + 0x30);

/// DBGPAUSE
const DBGPAUSE_val = packed struct {
/// unused [0:0]
_unused0: u1 = 1,
/// DBG0 [1:1]
/// Pause when processor 0 is in debug mode
DBG0: u1 = 1,
/// DBG1 [2:2]
/// Pause when processor 1 is in debug mode
DBG1: u1 = 1,
/// unused [3:31]
_unused3: u5 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Set bits high to enable pause when the corresponding debug ports are active
pub const DBGPAUSE = Register(DBGPAUSE_val).init(base_address + 0x2c);

/// TIMERAWL
const TIMERAWL_val = packed struct {
TIMERAWL_0: u8 = 0,
TIMERAWL_1: u8 = 0,
TIMERAWL_2: u8 = 0,
TIMERAWL_3: u8 = 0,
};
/// Raw read from bits 31:0 of time (no side effects)
pub const TIMERAWL = Register(TIMERAWL_val).init(base_address + 0x28);

/// TIMERAWH
const TIMERAWH_val = packed struct {
TIMERAWH_0: u8 = 0,
TIMERAWH_1: u8 = 0,
TIMERAWH_2: u8 = 0,
TIMERAWH_3: u8 = 0,
};
/// Raw read from bits 63:32 of time (no side effects)
pub const TIMERAWH = Register(TIMERAWH_val).init(base_address + 0x24);

/// ARMED
const ARMED_val = packed struct {
/// ARMED [0:3]
/// No description
ARMED: u4 = 0,
/// unused [4:31]
_unused4: u4 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Indicates the armed/disarmed status of each alarm.\n
pub const ARMED = Register(ARMED_val).init(base_address + 0x20);

/// ALARM3
const ALARM3_val = packed struct {
ALARM3_0: u8 = 0,
ALARM3_1: u8 = 0,
ALARM3_2: u8 = 0,
ALARM3_3: u8 = 0,
};
/// Arm alarm 3, and configure the time it will fire.\n
pub const ALARM3 = Register(ALARM3_val).init(base_address + 0x1c);

/// ALARM2
const ALARM2_val = packed struct {
ALARM2_0: u8 = 0,
ALARM2_1: u8 = 0,
ALARM2_2: u8 = 0,
ALARM2_3: u8 = 0,
};
/// Arm alarm 2, and configure the time it will fire.\n
pub const ALARM2 = Register(ALARM2_val).init(base_address + 0x18);

/// ALARM1
const ALARM1_val = packed struct {
ALARM1_0: u8 = 0,
ALARM1_1: u8 = 0,
ALARM1_2: u8 = 0,
ALARM1_3: u8 = 0,
};
/// Arm alarm 1, and configure the time it will fire.\n
pub const ALARM1 = Register(ALARM1_val).init(base_address + 0x14);

/// ALARM0
const ALARM0_val = packed struct {
ALARM0_0: u8 = 0,
ALARM0_1: u8 = 0,
ALARM0_2: u8 = 0,
ALARM0_3: u8 = 0,
};
/// Arm alarm 0, and configure the time it will fire.\n
pub const ALARM0 = Register(ALARM0_val).init(base_address + 0x10);

/// TIMELR
const TIMELR_val = packed struct {
TIMELR_0: u8 = 0,
TIMELR_1: u8 = 0,
TIMELR_2: u8 = 0,
TIMELR_3: u8 = 0,
};
/// Read from bits 31:0 of time
pub const TIMELR = Register(TIMELR_val).init(base_address + 0xc);

/// TIMEHR
const TIMEHR_val = packed struct {
TIMEHR_0: u8 = 0,
TIMEHR_1: u8 = 0,
TIMEHR_2: u8 = 0,
TIMEHR_3: u8 = 0,
};
/// Read from bits 63:32 of time\n
pub const TIMEHR = Register(TIMEHR_val).init(base_address + 0x8);

/// TIMELW
const TIMELW_val = packed struct {
TIMELW_0: u8 = 0,
TIMELW_1: u8 = 0,
TIMELW_2: u8 = 0,
TIMELW_3: u8 = 0,
};
/// Write to bits 31:0 of time\n
pub const TIMELW = Register(TIMELW_val).init(base_address + 0x4);

/// TIMEHW
const TIMEHW_val = packed struct {
TIMEHW_0: u8 = 0,
TIMEHW_1: u8 = 0,
TIMEHW_2: u8 = 0,
TIMEHW_3: u8 = 0,
};
/// Write to bits 63:32 of time\n
pub const TIMEHW = Register(TIMEHW_val).init(base_address + 0x0);
};

/// No description
pub const WATCHDOG = struct {

const base_address = 0x40058000;
/// TICK
const TICK_val = packed struct {
/// CYCLES [0:8]
/// Total number of clk_tick cycles before the next tick.
CYCLES: u9 = 0,
/// ENABLE [9:9]
/// start / stop tick generation
ENABLE: u1 = 1,
/// RUNNING [10:10]
/// Is the tick generator running?
RUNNING: u1 = 0,
/// COUNT [11:19]
/// Count down timer: the remaining number clk_tick cycles before the next tick is generated.
COUNT: u9 = 0,
/// unused [20:31]
_unused20: u4 = 0,
_unused24: u8 = 0,
};
/// Controls the tick generator
pub const TICK = Register(TICK_val).init(base_address + 0x2c);

/// SCRATCH7
const SCRATCH7_val = packed struct {
SCRATCH7_0: u8 = 0,
SCRATCH7_1: u8 = 0,
SCRATCH7_2: u8 = 0,
SCRATCH7_3: u8 = 0,
};
/// Scratch register. Information persists through soft reset of the chip.
pub const SCRATCH7 = Register(SCRATCH7_val).init(base_address + 0x28);

/// SCRATCH6
const SCRATCH6_val = packed struct {
SCRATCH6_0: u8 = 0,
SCRATCH6_1: u8 = 0,
SCRATCH6_2: u8 = 0,
SCRATCH6_3: u8 = 0,
};
/// Scratch register. Information persists through soft reset of the chip.
pub const SCRATCH6 = Register(SCRATCH6_val).init(base_address + 0x24);

/// SCRATCH5
const SCRATCH5_val = packed struct {
SCRATCH5_0: u8 = 0,
SCRATCH5_1: u8 = 0,
SCRATCH5_2: u8 = 0,
SCRATCH5_3: u8 = 0,
};
/// Scratch register. Information persists through soft reset of the chip.
pub const SCRATCH5 = Register(SCRATCH5_val).init(base_address + 0x20);

/// SCRATCH4
const SCRATCH4_val = packed struct {
SCRATCH4_0: u8 = 0,
SCRATCH4_1: u8 = 0,
SCRATCH4_2: u8 = 0,
SCRATCH4_3: u8 = 0,
};
/// Scratch register. Information persists through soft reset of the chip.
pub const SCRATCH4 = Register(SCRATCH4_val).init(base_address + 0x1c);

/// SCRATCH3
const SCRATCH3_val = packed struct {
SCRATCH3_0: u8 = 0,
SCRATCH3_1: u8 = 0,
SCRATCH3_2: u8 = 0,
SCRATCH3_3: u8 = 0,
};
/// Scratch register. Information persists through soft reset of the chip.
pub const SCRATCH3 = Register(SCRATCH3_val).init(base_address + 0x18);

/// SCRATCH2
const SCRATCH2_val = packed struct {
SCRATCH2_0: u8 = 0,
SCRATCH2_1: u8 = 0,
SCRATCH2_2: u8 = 0,
SCRATCH2_3: u8 = 0,
};
/// Scratch register. Information persists through soft reset of the chip.
pub const SCRATCH2 = Register(SCRATCH2_val).init(base_address + 0x14);

/// SCRATCH1
const SCRATCH1_val = packed struct {
SCRATCH1_0: u8 = 0,
SCRATCH1_1: u8 = 0,
SCRATCH1_2: u8 = 0,
SCRATCH1_3: u8 = 0,
};
/// Scratch register. Information persists through soft reset of the chip.
pub const SCRATCH1 = Register(SCRATCH1_val).init(base_address + 0x10);

/// SCRATCH0
const SCRATCH0_val = packed struct {
SCRATCH0_0: u8 = 0,
SCRATCH0_1: u8 = 0,
SCRATCH0_2: u8 = 0,
SCRATCH0_3: u8 = 0,
};
/// Scratch register. Information persists through soft reset of the chip.
pub const SCRATCH0 = Register(SCRATCH0_val).init(base_address + 0xc);

/// REASON
const REASON_val = packed struct {
/// TIMER [0:0]
/// No description
TIMER: u1 = 0,
/// FORCE [1:1]
/// No description
FORCE: u1 = 0,
/// unused [2:31]
_unused2: u6 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Logs the reason for the last reset. Both bits are zero for the case of a hardware reset.
pub const REASON = Register(REASON_val).init(base_address + 0x8);

/// LOAD
const LOAD_val = packed struct {
/// LOAD [0:23]
/// No description
LOAD: u24 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// Load the watchdog timer. The maximum setting is 0xffffff which corresponds to 0xffffff / 2 ticks before triggering a watchdog reset (see errata RP2040-E1).
pub const LOAD = Register(LOAD_val).init(base_address + 0x4);

/// CTRL
const CTRL_val = packed struct {
/// TIME [0:23]
/// Indicates the number of ticks / 2 (see errata RP2040-E1) before a watchdog reset will be triggered
TIME: u24 = 0,
/// PAUSE_JTAG [24:24]
/// Pause the watchdog timer when JTAG is accessing the bus fabric
PAUSE_JTAG: u1 = 1,
/// PAUSE_DBG0 [25:25]
/// Pause the watchdog timer when processor 0 is in debug mode
PAUSE_DBG0: u1 = 1,
/// PAUSE_DBG1 [26:26]
/// Pause the watchdog timer when processor 1 is in debug mode
PAUSE_DBG1: u1 = 1,
/// unused [27:29]
_unused27: u3 = 0,
/// ENABLE [30:30]
/// When not enabled the watchdog timer is paused
ENABLE: u1 = 0,
/// TRIGGER [31:31]
/// Trigger a watchdog reset
TRIGGER: u1 = 0,
};
/// Watchdog control\n
pub const CTRL = Register(CTRL_val).init(base_address + 0x0);
};

/// Register block to control RTC
pub const RTC = struct {

const base_address = 0x4005c000;
/// INTS
const INTS_val = packed struct {
/// RTC [0:0]
/// No description
RTC: u1 = 0,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Interrupt status after masking &amp; forcing
pub const INTS = Register(INTS_val).init(base_address + 0x2c);

/// INTF
const INTF_val = packed struct {
/// RTC [0:0]
/// No description
RTC: u1 = 0,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Interrupt Force
pub const INTF = Register(INTF_val).init(base_address + 0x28);

/// INTE
const INTE_val = packed struct {
/// RTC [0:0]
/// No description
RTC: u1 = 0,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Interrupt Enable
pub const INTE = Register(INTE_val).init(base_address + 0x24);

/// INTR
const INTR_val = packed struct {
/// RTC [0:0]
/// No description
RTC: u1 = 0,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Raw Interrupts
pub const INTR = Register(INTR_val).init(base_address + 0x20);

/// RTC_0
const RTC_0_val = packed struct {
/// SEC [0:5]
/// Seconds
SEC: u6 = 0,
/// unused [6:7]
_unused6: u2 = 0,
/// MIN [8:13]
/// Minutes
MIN: u6 = 0,
/// unused [14:15]
_unused14: u2 = 0,
/// HOUR [16:20]
/// Hours
HOUR: u5 = 0,
/// unused [21:23]
_unused21: u3 = 0,
/// DOTW [24:26]
/// Day of the week
DOTW: u3 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// RTC register 0\n
pub const RTC_0 = Register(RTC_0_val).init(base_address + 0x1c);

/// RTC_1
const RTC_1_val = packed struct {
/// DAY [0:4]
/// Day of the month (1..31)
DAY: u5 = 0,
/// unused [5:7]
_unused5: u3 = 0,
/// MONTH [8:11]
/// Month (1..12)
MONTH: u4 = 0,
/// YEAR [12:23]
/// Year
YEAR: u12 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// RTC register 1.
pub const RTC_1 = Register(RTC_1_val).init(base_address + 0x18);

/// IRQ_SETUP_1
const IRQ_SETUP_1_val = packed struct {
/// SEC [0:5]
/// Seconds
SEC: u6 = 0,
/// unused [6:7]
_unused6: u2 = 0,
/// MIN [8:13]
/// Minutes
MIN: u6 = 0,
/// unused [14:15]
_unused14: u2 = 0,
/// HOUR [16:20]
/// Hours
HOUR: u5 = 0,
/// unused [21:23]
_unused21: u3 = 0,
/// DOTW [24:26]
/// Day of the week
DOTW: u3 = 0,
/// unused [27:27]
_unused27: u1 = 0,
/// SEC_ENA [28:28]
/// Enable second matching
SEC_ENA: u1 = 0,
/// MIN_ENA [29:29]
/// Enable minute matching
MIN_ENA: u1 = 0,
/// HOUR_ENA [30:30]
/// Enable hour matching
HOUR_ENA: u1 = 0,
/// DOTW_ENA [31:31]
/// Enable day of the week matching
DOTW_ENA: u1 = 0,
};
/// Interrupt setup register 1
pub const IRQ_SETUP_1 = Register(IRQ_SETUP_1_val).init(base_address + 0x14);

/// IRQ_SETUP_0
const IRQ_SETUP_0_val = packed struct {
/// DAY [0:4]
/// Day of the month (1..31)
DAY: u5 = 0,
/// unused [5:7]
_unused5: u3 = 0,
/// MONTH [8:11]
/// Month (1..12)
MONTH: u4 = 0,
/// YEAR [12:23]
/// Year
YEAR: u12 = 0,
/// DAY_ENA [24:24]
/// Enable day matching
DAY_ENA: u1 = 0,
/// MONTH_ENA [25:25]
/// Enable month matching
MONTH_ENA: u1 = 0,
/// YEAR_ENA [26:26]
/// Enable year matching
YEAR_ENA: u1 = 0,
/// unused [27:27]
_unused27: u1 = 0,
/// MATCH_ENA [28:28]
/// Global match enable. Don't change any other value while this one is enabled
MATCH_ENA: u1 = 0,
/// MATCH_ACTIVE [29:29]
/// No description
MATCH_ACTIVE: u1 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// Interrupt setup register 0
pub const IRQ_SETUP_0 = Register(IRQ_SETUP_0_val).init(base_address + 0x10);

/// CTRL
const CTRL_val = packed struct {
/// RTC_ENABLE [0:0]
/// Enable RTC
RTC_ENABLE: u1 = 0,
/// RTC_ACTIVE [1:1]
/// RTC enabled (running)
RTC_ACTIVE: u1 = 0,
/// unused [2:3]
_unused2: u2 = 0,
/// LOAD [4:4]
/// Load RTC
LOAD: u1 = 0,
/// unused [5:7]
_unused5: u3 = 0,
/// FORCE_NOTLEAPYEAR [8:8]
/// If set, leapyear is forced off.\n
FORCE_NOTLEAPYEAR: u1 = 0,
/// unused [9:31]
_unused9: u7 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// RTC Control and status
pub const CTRL = Register(CTRL_val).init(base_address + 0xc);

/// SETUP_1
const SETUP_1_val = packed struct {
/// SEC [0:5]
/// Seconds
SEC: u6 = 0,
/// unused [6:7]
_unused6: u2 = 0,
/// MIN [8:13]
/// Minutes
MIN: u6 = 0,
/// unused [14:15]
_unused14: u2 = 0,
/// HOUR [16:20]
/// Hours
HOUR: u5 = 0,
/// unused [21:23]
_unused21: u3 = 0,
/// DOTW [24:26]
/// Day of the week: 1-Monday...0-Sunday ISO 8601 mod 7
DOTW: u3 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// RTC setup register 1
pub const SETUP_1 = Register(SETUP_1_val).init(base_address + 0x8);

/// SETUP_0
const SETUP_0_val = packed struct {
/// DAY [0:4]
/// Day of the month (1..31)
DAY: u5 = 0,
/// unused [5:7]
_unused5: u3 = 0,
/// MONTH [8:11]
/// Month (1..12)
MONTH: u4 = 0,
/// YEAR [12:23]
/// Year
YEAR: u12 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// RTC setup register 0
pub const SETUP_0 = Register(SETUP_0_val).init(base_address + 0x4);

/// CLKDIV_M1
const CLKDIV_M1_val = packed struct {
/// CLKDIV_M1 [0:15]
/// No description
CLKDIV_M1: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Divider minus 1 for the 1 second counter. Safe to change the value when RTC is not enabled.
pub const CLKDIV_M1 = Register(CLKDIV_M1_val).init(base_address + 0x0);
};

/// No description
pub const ROSC = struct {

const base_address = 0x40060000;
/// COUNT
const COUNT_val = packed struct {
/// COUNT [0:7]
/// No description
COUNT: u8 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// A down counter running at the ROSC frequency which counts to zero and stops.\n
pub const COUNT = Register(COUNT_val).init(base_address + 0x20);

/// RANDOMBIT
const RANDOMBIT_val = packed struct {
/// RANDOMBIT [0:0]
/// No description
RANDOMBIT: u1 = 1,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// This just reads the state of the oscillator output so randomness is compromised if the ring oscillator is stopped or run at a harmonic of the bus frequency
pub const RANDOMBIT = Register(RANDOMBIT_val).init(base_address + 0x1c);

/// STATUS
const STATUS_val = packed struct {
/// unused [0:11]
_unused0: u8 = 0,
_unused8: u4 = 0,
/// ENABLED [12:12]
/// Oscillator is enabled but not necessarily running and stable\n
ENABLED: u1 = 0,
/// unused [13:15]
_unused13: u3 = 0,
/// DIV_RUNNING [16:16]
/// post-divider is running\n
DIV_RUNNING: u1 = 0,
/// unused [17:23]
_unused17: u7 = 0,
/// BADWRITE [24:24]
/// An invalid value has been written to CTRL_ENABLE or CTRL_FREQ_RANGE or FREQA or FREQB or DIV or PHASE or DORMANT
BADWRITE: u1 = 0,
/// unused [25:30]
_unused25: u6 = 0,
/// STABLE [31:31]
/// Oscillator is running and stable
STABLE: u1 = 0,
};
/// Ring Oscillator Status
pub const STATUS = Register(STATUS_val).init(base_address + 0x18);

/// PHASE
const PHASE_val = packed struct {
/// SHIFT [0:1]
/// phase shift the phase-shifted output by SHIFT input clocks\n
SHIFT: u2 = 0,
/// FLIP [2:2]
/// invert the phase-shifted output\n
FLIP: u1 = 0,
/// ENABLE [3:3]
/// enable the phase-shifted output\n
ENABLE: u1 = 1,
/// PASSWD [4:11]
/// set to 0xaa\n
PASSWD: u8 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Controls the phase shifted output
pub const PHASE = Register(PHASE_val).init(base_address + 0x14);

/// DIV
const DIV_val = packed struct {
/// DIV [0:11]
/// set to 0xaa0 + div where\n
DIV: u12 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Controls the output divider
pub const DIV = Register(DIV_val).init(base_address + 0x10);

/// DORMANT
const DORMANT_val = packed struct {
DORMANT_0: u8 = 0,
DORMANT_1: u8 = 0,
DORMANT_2: u8 = 0,
DORMANT_3: u8 = 0,
};
/// Ring Oscillator pause control\n
pub const DORMANT = Register(DORMANT_val).init(base_address + 0xc);

/// FREQB
const FREQB_val = packed struct {
/// DS4 [0:2]
/// Stage 4 drive strength
DS4: u3 = 0,
/// unused [3:3]
_unused3: u1 = 0,
/// DS5 [4:6]
/// Stage 5 drive strength
DS5: u3 = 0,
/// unused [7:7]
_unused7: u1 = 0,
/// DS6 [8:10]
/// Stage 6 drive strength
DS6: u3 = 0,
/// unused [11:11]
_unused11: u1 = 0,
/// DS7 [12:14]
/// Stage 7 drive strength
DS7: u3 = 0,
/// unused [15:15]
_unused15: u1 = 0,
/// PASSWD [16:31]
/// Set to 0x9696 to apply the settings\n
PASSWD: u16 = 0,
};
/// For a detailed description see freqa register
pub const FREQB = Register(FREQB_val).init(base_address + 0x8);

/// FREQA
const FREQA_val = packed struct {
/// DS0 [0:2]
/// Stage 0 drive strength
DS0: u3 = 0,
/// unused [3:3]
_unused3: u1 = 0,
/// DS1 [4:6]
/// Stage 1 drive strength
DS1: u3 = 0,
/// unused [7:7]
_unused7: u1 = 0,
/// DS2 [8:10]
/// Stage 2 drive strength
DS2: u3 = 0,
/// unused [11:11]
_unused11: u1 = 0,
/// DS3 [12:14]
/// Stage 3 drive strength
DS3: u3 = 0,
/// unused [15:15]
_unused15: u1 = 0,
/// PASSWD [16:31]
/// Set to 0x9696 to apply the settings\n
PASSWD: u16 = 0,
};
/// The FREQA &amp; FREQB registers control the frequency by controlling the drive strength of each stage\n
pub const FREQA = Register(FREQA_val).init(base_address + 0x4);

/// CTRL
const CTRL_val = packed struct {
/// FREQ_RANGE [0:11]
/// Controls the number of delay stages in the ROSC ring\n
FREQ_RANGE: u12 = 2720,
/// ENABLE [12:23]
/// On power-up this field is initialised to ENABLE\n
ENABLE: u12 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// Ring Oscillator control
pub const CTRL = Register(CTRL_val).init(base_address + 0x0);
};

/// control and status for on-chip voltage regulator and chip level reset subsystem
pub const VREG_AND_CHIP_RESET = struct {

const base_address = 0x40064000;
/// CHIP_RESET
const CHIP_RESET_val = packed struct {
/// unused [0:7]
_unused0: u8 = 0,
/// HAD_POR [8:8]
/// Last reset was from the power-on reset or brown-out detection blocks
HAD_POR: u1 = 0,
/// unused [9:15]
_unused9: u7 = 0,
/// HAD_RUN [16:16]
/// Last reset was from the RUN pin
HAD_RUN: u1 = 0,
/// unused [17:19]
_unused17: u3 = 0,
/// HAD_PSM_RESTART [20:20]
/// Last reset was from the debug port
HAD_PSM_RESTART: u1 = 0,
/// unused [21:23]
_unused21: u3 = 0,
/// PSM_RESTART_FLAG [24:24]
/// This is set by psm_restart from the debugger.\n
PSM_RESTART_FLAG: u1 = 0,
/// unused [25:31]
_unused25: u7 = 0,
};
/// Chip reset control and status
pub const CHIP_RESET = Register(CHIP_RESET_val).init(base_address + 0x8);

/// BOD
const BOD_val = packed struct {
/// EN [0:0]
/// enable\n
EN: u1 = 1,
/// unused [1:3]
_unused1: u3 = 0,
/// VSEL [4:7]
/// threshold select\n
VSEL: u4 = 9,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// brown-out detection control
pub const BOD = Register(BOD_val).init(base_address + 0x4);

/// VREG
const VREG_val = packed struct {
/// EN [0:0]
/// enable\n
EN: u1 = 1,
/// HIZ [1:1]
/// high impedance mode select\n
HIZ: u1 = 0,
/// unused [2:3]
_unused2: u2 = 0,
/// VSEL [4:7]
/// output voltage select\n
VSEL: u4 = 11,
/// unused [8:11]
_unused8: u4 = 0,
/// ROK [12:12]
/// regulation status\n
ROK: u1 = 0,
/// unused [13:31]
_unused13: u3 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Voltage regulator control and status
pub const VREG = Register(VREG_val).init(base_address + 0x0);
};

/// Testbench manager. Allows the programmer to know what platform their software is running on.
pub const TBMAN = struct {

const base_address = 0x4006c000;
/// PLATFORM
const PLATFORM_val = packed struct {
/// ASIC [0:0]
/// Indicates the platform is an ASIC
ASIC: u1 = 1,
/// FPGA [1:1]
/// Indicates the platform is an FPGA
FPGA: u1 = 0,
/// unused [2:31]
_unused2: u6 = 1,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Indicates the type of platform in use
pub const PLATFORM = Register(PLATFORM_val).init(base_address + 0x0);
};

/// DMA with separate read and write masters
pub const DMA = struct {

const base_address = 0x50000000;
/// CH11_DBG_TCR
const CH11_DBG_TCR_val = packed struct {
CH11_DBG_TCR_0: u8 = 0,
CH11_DBG_TCR_1: u8 = 0,
CH11_DBG_TCR_2: u8 = 0,
CH11_DBG_TCR_3: u8 = 0,
};
/// Read to get channel TRANS_COUNT reload value, i.e. the length of the next transfer
pub const CH11_DBG_TCR = Register(CH11_DBG_TCR_val).init(base_address + 0xac4);

/// CH11_DBG_CTDREQ
const CH11_DBG_CTDREQ_val = packed struct {
/// CH11_DBG_CTDREQ [0:5]
/// No description
CH11_DBG_CTDREQ: u6 = 0,
/// unused [6:31]
_unused6: u2 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Read: get channel DREQ counter (i.e. how many accesses the DMA expects it can perform on the peripheral without overflow/underflow. Write any value: clears the counter, and cause channel to re-initiate DREQ handshake.
pub const CH11_DBG_CTDREQ = Register(CH11_DBG_CTDREQ_val).init(base_address + 0xac0);

/// CH10_DBG_TCR
const CH10_DBG_TCR_val = packed struct {
CH10_DBG_TCR_0: u8 = 0,
CH10_DBG_TCR_1: u8 = 0,
CH10_DBG_TCR_2: u8 = 0,
CH10_DBG_TCR_3: u8 = 0,
};
/// Read to get channel TRANS_COUNT reload value, i.e. the length of the next transfer
pub const CH10_DBG_TCR = Register(CH10_DBG_TCR_val).init(base_address + 0xa84);

/// CH10_DBG_CTDREQ
const CH10_DBG_CTDREQ_val = packed struct {
/// CH10_DBG_CTDREQ [0:5]
/// No description
CH10_DBG_CTDREQ: u6 = 0,
/// unused [6:31]
_unused6: u2 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Read: get channel DREQ counter (i.e. how many accesses the DMA expects it can perform on the peripheral without overflow/underflow. Write any value: clears the counter, and cause channel to re-initiate DREQ handshake.
pub const CH10_DBG_CTDREQ = Register(CH10_DBG_CTDREQ_val).init(base_address + 0xa80);

/// CH9_DBG_TCR
const CH9_DBG_TCR_val = packed struct {
CH9_DBG_TCR_0: u8 = 0,
CH9_DBG_TCR_1: u8 = 0,
CH9_DBG_TCR_2: u8 = 0,
CH9_DBG_TCR_3: u8 = 0,
};
/// Read to get channel TRANS_COUNT reload value, i.e. the length of the next transfer
pub const CH9_DBG_TCR = Register(CH9_DBG_TCR_val).init(base_address + 0xa44);

/// CH9_DBG_CTDREQ
const CH9_DBG_CTDREQ_val = packed struct {
/// CH9_DBG_CTDREQ [0:5]
/// No description
CH9_DBG_CTDREQ: u6 = 0,
/// unused [6:31]
_unused6: u2 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Read: get channel DREQ counter (i.e. how many accesses the DMA expects it can perform on the peripheral without overflow/underflow. Write any value: clears the counter, and cause channel to re-initiate DREQ handshake.
pub const CH9_DBG_CTDREQ = Register(CH9_DBG_CTDREQ_val).init(base_address + 0xa40);

/// CH8_DBG_TCR
const CH8_DBG_TCR_val = packed struct {
CH8_DBG_TCR_0: u8 = 0,
CH8_DBG_TCR_1: u8 = 0,
CH8_DBG_TCR_2: u8 = 0,
CH8_DBG_TCR_3: u8 = 0,
};
/// Read to get channel TRANS_COUNT reload value, i.e. the length of the next transfer
pub const CH8_DBG_TCR = Register(CH8_DBG_TCR_val).init(base_address + 0xa04);

/// CH8_DBG_CTDREQ
const CH8_DBG_CTDREQ_val = packed struct {
/// CH8_DBG_CTDREQ [0:5]
/// No description
CH8_DBG_CTDREQ: u6 = 0,
/// unused [6:31]
_unused6: u2 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Read: get channel DREQ counter (i.e. how many accesses the DMA expects it can perform on the peripheral without overflow/underflow. Write any value: clears the counter, and cause channel to re-initiate DREQ handshake.
pub const CH8_DBG_CTDREQ = Register(CH8_DBG_CTDREQ_val).init(base_address + 0xa00);

/// CH7_DBG_TCR
const CH7_DBG_TCR_val = packed struct {
CH7_DBG_TCR_0: u8 = 0,
CH7_DBG_TCR_1: u8 = 0,
CH7_DBG_TCR_2: u8 = 0,
CH7_DBG_TCR_3: u8 = 0,
};
/// Read to get channel TRANS_COUNT reload value, i.e. the length of the next transfer
pub const CH7_DBG_TCR = Register(CH7_DBG_TCR_val).init(base_address + 0x9c4);

/// CH7_DBG_CTDREQ
const CH7_DBG_CTDREQ_val = packed struct {
/// CH7_DBG_CTDREQ [0:5]
/// No description
CH7_DBG_CTDREQ: u6 = 0,
/// unused [6:31]
_unused6: u2 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Read: get channel DREQ counter (i.e. how many accesses the DMA expects it can perform on the peripheral without overflow/underflow. Write any value: clears the counter, and cause channel to re-initiate DREQ handshake.
pub const CH7_DBG_CTDREQ = Register(CH7_DBG_CTDREQ_val).init(base_address + 0x9c0);

/// CH6_DBG_TCR
const CH6_DBG_TCR_val = packed struct {
CH6_DBG_TCR_0: u8 = 0,
CH6_DBG_TCR_1: u8 = 0,
CH6_DBG_TCR_2: u8 = 0,
CH6_DBG_TCR_3: u8 = 0,
};
/// Read to get channel TRANS_COUNT reload value, i.e. the length of the next transfer
pub const CH6_DBG_TCR = Register(CH6_DBG_TCR_val).init(base_address + 0x984);

/// CH6_DBG_CTDREQ
const CH6_DBG_CTDREQ_val = packed struct {
/// CH6_DBG_CTDREQ [0:5]
/// No description
CH6_DBG_CTDREQ: u6 = 0,
/// unused [6:31]
_unused6: u2 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Read: get channel DREQ counter (i.e. how many accesses the DMA expects it can perform on the peripheral without overflow/underflow. Write any value: clears the counter, and cause channel to re-initiate DREQ handshake.
pub const CH6_DBG_CTDREQ = Register(CH6_DBG_CTDREQ_val).init(base_address + 0x980);

/// CH5_DBG_TCR
const CH5_DBG_TCR_val = packed struct {
CH5_DBG_TCR_0: u8 = 0,
CH5_DBG_TCR_1: u8 = 0,
CH5_DBG_TCR_2: u8 = 0,
CH5_DBG_TCR_3: u8 = 0,
};
/// Read to get channel TRANS_COUNT reload value, i.e. the length of the next transfer
pub const CH5_DBG_TCR = Register(CH5_DBG_TCR_val).init(base_address + 0x944);

/// CH5_DBG_CTDREQ
const CH5_DBG_CTDREQ_val = packed struct {
/// CH5_DBG_CTDREQ [0:5]
/// No description
CH5_DBG_CTDREQ: u6 = 0,
/// unused [6:31]
_unused6: u2 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Read: get channel DREQ counter (i.e. how many accesses the DMA expects it can perform on the peripheral without overflow/underflow. Write any value: clears the counter, and cause channel to re-initiate DREQ handshake.
pub const CH5_DBG_CTDREQ = Register(CH5_DBG_CTDREQ_val).init(base_address + 0x940);

/// CH4_DBG_TCR
const CH4_DBG_TCR_val = packed struct {
CH4_DBG_TCR_0: u8 = 0,
CH4_DBG_TCR_1: u8 = 0,
CH4_DBG_TCR_2: u8 = 0,
CH4_DBG_TCR_3: u8 = 0,
};
/// Read to get channel TRANS_COUNT reload value, i.e. the length of the next transfer
pub const CH4_DBG_TCR = Register(CH4_DBG_TCR_val).init(base_address + 0x904);

/// CH4_DBG_CTDREQ
const CH4_DBG_CTDREQ_val = packed struct {
/// CH4_DBG_CTDREQ [0:5]
/// No description
CH4_DBG_CTDREQ: u6 = 0,
/// unused [6:31]
_unused6: u2 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Read: get channel DREQ counter (i.e. how many accesses the DMA expects it can perform on the peripheral without overflow/underflow. Write any value: clears the counter, and cause channel to re-initiate DREQ handshake.
pub const CH4_DBG_CTDREQ = Register(CH4_DBG_CTDREQ_val).init(base_address + 0x900);

/// CH3_DBG_TCR
const CH3_DBG_TCR_val = packed struct {
CH3_DBG_TCR_0: u8 = 0,
CH3_DBG_TCR_1: u8 = 0,
CH3_DBG_TCR_2: u8 = 0,
CH3_DBG_TCR_3: u8 = 0,
};
/// Read to get channel TRANS_COUNT reload value, i.e. the length of the next transfer
pub const CH3_DBG_TCR = Register(CH3_DBG_TCR_val).init(base_address + 0x8c4);

/// CH3_DBG_CTDREQ
const CH3_DBG_CTDREQ_val = packed struct {
/// CH3_DBG_CTDREQ [0:5]
/// No description
CH3_DBG_CTDREQ: u6 = 0,
/// unused [6:31]
_unused6: u2 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Read: get channel DREQ counter (i.e. how many accesses the DMA expects it can perform on the peripheral without overflow/underflow. Write any value: clears the counter, and cause channel to re-initiate DREQ handshake.
pub const CH3_DBG_CTDREQ = Register(CH3_DBG_CTDREQ_val).init(base_address + 0x8c0);

/// CH2_DBG_TCR
const CH2_DBG_TCR_val = packed struct {
CH2_DBG_TCR_0: u8 = 0,
CH2_DBG_TCR_1: u8 = 0,
CH2_DBG_TCR_2: u8 = 0,
CH2_DBG_TCR_3: u8 = 0,
};
/// Read to get channel TRANS_COUNT reload value, i.e. the length of the next transfer
pub const CH2_DBG_TCR = Register(CH2_DBG_TCR_val).init(base_address + 0x884);

/// CH2_DBG_CTDREQ
const CH2_DBG_CTDREQ_val = packed struct {
/// CH2_DBG_CTDREQ [0:5]
/// No description
CH2_DBG_CTDREQ: u6 = 0,
/// unused [6:31]
_unused6: u2 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Read: get channel DREQ counter (i.e. how many accesses the DMA expects it can perform on the peripheral without overflow/underflow. Write any value: clears the counter, and cause channel to re-initiate DREQ handshake.
pub const CH2_DBG_CTDREQ = Register(CH2_DBG_CTDREQ_val).init(base_address + 0x880);

/// CH1_DBG_TCR
const CH1_DBG_TCR_val = packed struct {
CH1_DBG_TCR_0: u8 = 0,
CH1_DBG_TCR_1: u8 = 0,
CH1_DBG_TCR_2: u8 = 0,
CH1_DBG_TCR_3: u8 = 0,
};
/// Read to get channel TRANS_COUNT reload value, i.e. the length of the next transfer
pub const CH1_DBG_TCR = Register(CH1_DBG_TCR_val).init(base_address + 0x844);

/// CH1_DBG_CTDREQ
const CH1_DBG_CTDREQ_val = packed struct {
/// CH1_DBG_CTDREQ [0:5]
/// No description
CH1_DBG_CTDREQ: u6 = 0,
/// unused [6:31]
_unused6: u2 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Read: get channel DREQ counter (i.e. how many accesses the DMA expects it can perform on the peripheral without overflow/underflow. Write any value: clears the counter, and cause channel to re-initiate DREQ handshake.
pub const CH1_DBG_CTDREQ = Register(CH1_DBG_CTDREQ_val).init(base_address + 0x840);

/// CH0_DBG_TCR
const CH0_DBG_TCR_val = packed struct {
CH0_DBG_TCR_0: u8 = 0,
CH0_DBG_TCR_1: u8 = 0,
CH0_DBG_TCR_2: u8 = 0,
CH0_DBG_TCR_3: u8 = 0,
};
/// Read to get channel TRANS_COUNT reload value, i.e. the length of the next transfer
pub const CH0_DBG_TCR = Register(CH0_DBG_TCR_val).init(base_address + 0x804);

/// CH0_DBG_CTDREQ
const CH0_DBG_CTDREQ_val = packed struct {
/// CH0_DBG_CTDREQ [0:5]
/// No description
CH0_DBG_CTDREQ: u6 = 0,
/// unused [6:31]
_unused6: u2 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Read: get channel DREQ counter (i.e. how many accesses the DMA expects it can perform on the peripheral without overflow/underflow. Write any value: clears the counter, and cause channel to re-initiate DREQ handshake.
pub const CH0_DBG_CTDREQ = Register(CH0_DBG_CTDREQ_val).init(base_address + 0x800);

/// N_CHANNELS
const N_CHANNELS_val = packed struct {
/// N_CHANNELS [0:4]
/// No description
N_CHANNELS: u5 = 0,
/// unused [5:31]
_unused5: u3 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// The number of channels this DMA instance is equipped with. This DMA supports up to 16 hardware channels, but can be configured with as few as one, to minimise silicon area.
pub const N_CHANNELS = Register(N_CHANNELS_val).init(base_address + 0x448);

/// CHAN_ABORT
const CHAN_ABORT_val = packed struct {
/// CHAN_ABORT [0:15]
/// Each bit corresponds to a channel. Writing a 1 aborts whatever transfer sequence is in progress on that channel. The bit will remain high until any in-flight transfers have been flushed through the address and data FIFOs.\n\n
CHAN_ABORT: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Abort an in-progress transfer sequence on one or more channels
pub const CHAN_ABORT = Register(CHAN_ABORT_val).init(base_address + 0x444);

/// FIFO_LEVELS
const FIFO_LEVELS_val = packed struct {
/// TDF_LVL [0:7]
/// Current Transfer-Data-FIFO fill level
TDF_LVL: u8 = 0,
/// WAF_LVL [8:15]
/// Current Write-Address-FIFO fill level
WAF_LVL: u8 = 0,
/// RAF_LVL [16:23]
/// Current Read-Address-FIFO fill level
RAF_LVL: u8 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// Debug RAF, WAF, TDF levels
pub const FIFO_LEVELS = Register(FIFO_LEVELS_val).init(base_address + 0x440);

/// SNIFF_DATA
const SNIFF_DATA_val = packed struct {
SNIFF_DATA_0: u8 = 0,
SNIFF_DATA_1: u8 = 0,
SNIFF_DATA_2: u8 = 0,
SNIFF_DATA_3: u8 = 0,
};
/// Data accumulator for sniff hardware\n
pub const SNIFF_DATA = Register(SNIFF_DATA_val).init(base_address + 0x438);

/// SNIFF_CTRL
const SNIFF_CTRL_val = packed struct {
/// EN [0:0]
/// Enable sniffer
EN: u1 = 0,
/// DMACH [1:4]
/// DMA channel for Sniffer to observe
DMACH: u4 = 0,
/// CALC [5:8]
/// No description
CALC: u4 = 0,
/// BSWAP [9:9]
/// Locally perform a byte reverse on the sniffed data, before feeding into checksum.\n\n
BSWAP: u1 = 0,
/// OUT_REV [10:10]
/// If set, the result appears bit-reversed when read. This does not affect the way the checksum is calculated; the result is transformed on-the-fly between the result register and the bus.
OUT_REV: u1 = 0,
/// OUT_INV [11:11]
/// If set, the result appears inverted (bitwise complement) when read. This does not affect the way the checksum is calculated; the result is transformed on-the-fly between the result register and the bus.
OUT_INV: u1 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Sniffer Control
pub const SNIFF_CTRL = Register(SNIFF_CTRL_val).init(base_address + 0x434);

/// MULTI_CHAN_TRIGGER
const MULTI_CHAN_TRIGGER_val = packed struct {
/// MULTI_CHAN_TRIGGER [0:15]
/// Each bit in this register corresponds to a DMA channel. Writing a 1 to the relevant bit is the same as writing to that channel's trigger register; the channel will start if it is currently enabled and not already busy.
MULTI_CHAN_TRIGGER: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Trigger one or more channels simultaneously
pub const MULTI_CHAN_TRIGGER = Register(MULTI_CHAN_TRIGGER_val).init(base_address + 0x430);

/// TIMER3
const TIMER3_val = packed struct {
/// Y [0:15]
/// Pacing Timer Divisor. Specifies the Y value for the (X/Y) fractional timer.
Y: u16 = 0,
/// X [16:31]
/// Pacing Timer Dividend. Specifies the X value for the (X/Y) fractional timer.
X: u16 = 0,
};
/// Pacing (X/Y) Fractional Timer\n
pub const TIMER3 = Register(TIMER3_val).init(base_address + 0x42c);

/// TIMER2
const TIMER2_val = packed struct {
/// Y [0:15]
/// Pacing Timer Divisor. Specifies the Y value for the (X/Y) fractional timer.
Y: u16 = 0,
/// X [16:31]
/// Pacing Timer Dividend. Specifies the X value for the (X/Y) fractional timer.
X: u16 = 0,
};
/// Pacing (X/Y) Fractional Timer\n
pub const TIMER2 = Register(TIMER2_val).init(base_address + 0x428);

/// TIMER1
const TIMER1_val = packed struct {
/// Y [0:15]
/// Pacing Timer Divisor. Specifies the Y value for the (X/Y) fractional timer.
Y: u16 = 0,
/// X [16:31]
/// Pacing Timer Dividend. Specifies the X value for the (X/Y) fractional timer.
X: u16 = 0,
};
/// Pacing (X/Y) Fractional Timer\n
pub const TIMER1 = Register(TIMER1_val).init(base_address + 0x424);

/// TIMER0
const TIMER0_val = packed struct {
/// Y [0:15]
/// Pacing Timer Divisor. Specifies the Y value for the (X/Y) fractional timer.
Y: u16 = 0,
/// X [16:31]
/// Pacing Timer Dividend. Specifies the X value for the (X/Y) fractional timer.
X: u16 = 0,
};
/// Pacing (X/Y) Fractional Timer\n
pub const TIMER0 = Register(TIMER0_val).init(base_address + 0x420);

/// INTS1
const INTS1_val = packed struct {
/// INTS1 [0:15]
/// Indicates active channel interrupt requests which are currently causing IRQ 1 to be asserted.\n
INTS1: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Interrupt Status (masked) for IRQ 1
pub const INTS1 = Register(INTS1_val).init(base_address + 0x41c);

/// INTF1
const INTF1_val = packed struct {
/// INTF1 [0:15]
/// Write 1s to force the corresponding bits in INTE0. The interrupt remains asserted until INTF0 is cleared.
INTF1: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Force Interrupts for IRQ 1
pub const INTF1 = Register(INTF1_val).init(base_address + 0x418);

/// INTE1
const INTE1_val = packed struct {
/// INTE1 [0:15]
/// Set bit n to pass interrupts from channel n to DMA IRQ 1.
INTE1: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Interrupt Enables for IRQ 1
pub const INTE1 = Register(INTE1_val).init(base_address + 0x414);

/// INTS0
const INTS0_val = packed struct {
/// INTS0 [0:15]
/// Indicates active channel interrupt requests which are currently causing IRQ 0 to be asserted.\n
INTS0: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Interrupt Status for IRQ 0
pub const INTS0 = Register(INTS0_val).init(base_address + 0x40c);

/// INTF0
const INTF0_val = packed struct {
/// INTF0 [0:15]
/// Write 1s to force the corresponding bits in INTE0. The interrupt remains asserted until INTF0 is cleared.
INTF0: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Force Interrupts
pub const INTF0 = Register(INTF0_val).init(base_address + 0x408);

/// INTE0
const INTE0_val = packed struct {
/// INTE0 [0:15]
/// Set bit n to pass interrupts from channel n to DMA IRQ 0.
INTE0: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Interrupt Enables for IRQ 0
pub const INTE0 = Register(INTE0_val).init(base_address + 0x404);

/// INTR
const INTR_val = packed struct {
/// INTR [0:15]
/// Raw interrupt status for DMA Channels 0..15. Bit n corresponds to channel n. Ignores any masking or forcing. Channel interrupts can be cleared by writing a bit mask to INTR, INTS0 or INTS1.\n\n
INTR: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Interrupt Status (raw)
pub const INTR = Register(INTR_val).init(base_address + 0x400);

/// CH11_AL3_READ_ADDR_TRIG
const CH11_AL3_READ_ADDR_TRIG_val = packed struct {
CH11_AL3_READ_ADDR_TRIG_0: u8 = 0,
CH11_AL3_READ_ADDR_TRIG_1: u8 = 0,
CH11_AL3_READ_ADDR_TRIG_2: u8 = 0,
CH11_AL3_READ_ADDR_TRIG_3: u8 = 0,
};
/// Alias for channel 11 READ_ADDR register\n
pub const CH11_AL3_READ_ADDR_TRIG = Register(CH11_AL3_READ_ADDR_TRIG_val).init(base_address + 0x2fc);

/// CH11_AL3_TRANS_COUNT
const CH11_AL3_TRANS_COUNT_val = packed struct {
CH11_AL3_TRANS_COUNT_0: u8 = 0,
CH11_AL3_TRANS_COUNT_1: u8 = 0,
CH11_AL3_TRANS_COUNT_2: u8 = 0,
CH11_AL3_TRANS_COUNT_3: u8 = 0,
};
/// Alias for channel 11 TRANS_COUNT register
pub const CH11_AL3_TRANS_COUNT = Register(CH11_AL3_TRANS_COUNT_val).init(base_address + 0x2f8);

/// CH11_AL3_WRITE_ADDR
const CH11_AL3_WRITE_ADDR_val = packed struct {
CH11_AL3_WRITE_ADDR_0: u8 = 0,
CH11_AL3_WRITE_ADDR_1: u8 = 0,
CH11_AL3_WRITE_ADDR_2: u8 = 0,
CH11_AL3_WRITE_ADDR_3: u8 = 0,
};
/// Alias for channel 11 WRITE_ADDR register
pub const CH11_AL3_WRITE_ADDR = Register(CH11_AL3_WRITE_ADDR_val).init(base_address + 0x2f4);

/// CH11_AL3_CTRL
const CH11_AL3_CTRL_val = packed struct {
CH11_AL3_CTRL_0: u8 = 0,
CH11_AL3_CTRL_1: u8 = 0,
CH11_AL3_CTRL_2: u8 = 0,
CH11_AL3_CTRL_3: u8 = 0,
};
/// Alias for channel 11 CTRL register
pub const CH11_AL3_CTRL = Register(CH11_AL3_CTRL_val).init(base_address + 0x2f0);

/// CH11_AL2_WRITE_ADDR_TRIG
const CH11_AL2_WRITE_ADDR_TRIG_val = packed struct {
CH11_AL2_WRITE_ADDR_TRIG_0: u8 = 0,
CH11_AL2_WRITE_ADDR_TRIG_1: u8 = 0,
CH11_AL2_WRITE_ADDR_TRIG_2: u8 = 0,
CH11_AL2_WRITE_ADDR_TRIG_3: u8 = 0,
};
/// Alias for channel 11 WRITE_ADDR register\n
pub const CH11_AL2_WRITE_ADDR_TRIG = Register(CH11_AL2_WRITE_ADDR_TRIG_val).init(base_address + 0x2ec);

/// CH11_AL2_READ_ADDR
const CH11_AL2_READ_ADDR_val = packed struct {
CH11_AL2_READ_ADDR_0: u8 = 0,
CH11_AL2_READ_ADDR_1: u8 = 0,
CH11_AL2_READ_ADDR_2: u8 = 0,
CH11_AL2_READ_ADDR_3: u8 = 0,
};
/// Alias for channel 11 READ_ADDR register
pub const CH11_AL2_READ_ADDR = Register(CH11_AL2_READ_ADDR_val).init(base_address + 0x2e8);

/// CH11_AL2_TRANS_COUNT
const CH11_AL2_TRANS_COUNT_val = packed struct {
CH11_AL2_TRANS_COUNT_0: u8 = 0,
CH11_AL2_TRANS_COUNT_1: u8 = 0,
CH11_AL2_TRANS_COUNT_2: u8 = 0,
CH11_AL2_TRANS_COUNT_3: u8 = 0,
};
/// Alias for channel 11 TRANS_COUNT register
pub const CH11_AL2_TRANS_COUNT = Register(CH11_AL2_TRANS_COUNT_val).init(base_address + 0x2e4);

/// CH11_AL2_CTRL
const CH11_AL2_CTRL_val = packed struct {
CH11_AL2_CTRL_0: u8 = 0,
CH11_AL2_CTRL_1: u8 = 0,
CH11_AL2_CTRL_2: u8 = 0,
CH11_AL2_CTRL_3: u8 = 0,
};
/// Alias for channel 11 CTRL register
pub const CH11_AL2_CTRL = Register(CH11_AL2_CTRL_val).init(base_address + 0x2e0);

/// CH11_AL1_TRANS_COUNT_TRIG
const CH11_AL1_TRANS_COUNT_TRIG_val = packed struct {
CH11_AL1_TRANS_COUNT_TRIG_0: u8 = 0,
CH11_AL1_TRANS_COUNT_TRIG_1: u8 = 0,
CH11_AL1_TRANS_COUNT_TRIG_2: u8 = 0,
CH11_AL1_TRANS_COUNT_TRIG_3: u8 = 0,
};
/// Alias for channel 11 TRANS_COUNT register\n
pub const CH11_AL1_TRANS_COUNT_TRIG = Register(CH11_AL1_TRANS_COUNT_TRIG_val).init(base_address + 0x2dc);

/// CH11_AL1_WRITE_ADDR
const CH11_AL1_WRITE_ADDR_val = packed struct {
CH11_AL1_WRITE_ADDR_0: u8 = 0,
CH11_AL1_WRITE_ADDR_1: u8 = 0,
CH11_AL1_WRITE_ADDR_2: u8 = 0,
CH11_AL1_WRITE_ADDR_3: u8 = 0,
};
/// Alias for channel 11 WRITE_ADDR register
pub const CH11_AL1_WRITE_ADDR = Register(CH11_AL1_WRITE_ADDR_val).init(base_address + 0x2d8);

/// CH11_AL1_READ_ADDR
const CH11_AL1_READ_ADDR_val = packed struct {
CH11_AL1_READ_ADDR_0: u8 = 0,
CH11_AL1_READ_ADDR_1: u8 = 0,
CH11_AL1_READ_ADDR_2: u8 = 0,
CH11_AL1_READ_ADDR_3: u8 = 0,
};
/// Alias for channel 11 READ_ADDR register
pub const CH11_AL1_READ_ADDR = Register(CH11_AL1_READ_ADDR_val).init(base_address + 0x2d4);

/// CH11_AL1_CTRL
const CH11_AL1_CTRL_val = packed struct {
CH11_AL1_CTRL_0: u8 = 0,
CH11_AL1_CTRL_1: u8 = 0,
CH11_AL1_CTRL_2: u8 = 0,
CH11_AL1_CTRL_3: u8 = 0,
};
/// Alias for channel 11 CTRL register
pub const CH11_AL1_CTRL = Register(CH11_AL1_CTRL_val).init(base_address + 0x2d0);

/// CH11_CTRL_TRIG
const CH11_CTRL_TRIG_val = packed struct {
/// EN [0:0]
/// DMA Channel Enable.\n
EN: u1 = 0,
/// HIGH_PRIORITY [1:1]
/// HIGH_PRIORITY gives a channel preferential treatment in issue scheduling: in each scheduling round, all high priority channels are considered first, and then only a single low priority channel, before returning to the high priority channels.\n\n
HIGH_PRIORITY: u1 = 0,
/// DATA_SIZE [2:3]
/// Set the size of each bus transfer (byte/halfword/word). READ_ADDR and WRITE_ADDR advance by this amount (1/2/4 bytes) with each transfer.
DATA_SIZE: u2 = 0,
/// INCR_READ [4:4]
/// If 1, the read address increments with each transfer. If 0, each read is directed to the same, initial address.\n\n
INCR_READ: u1 = 0,
/// INCR_WRITE [5:5]
/// If 1, the write address increments with each transfer. If 0, each write is directed to the same, initial address.\n\n
INCR_WRITE: u1 = 0,
/// RING_SIZE [6:9]
/// Size of address wrap region. If 0, don't wrap. For values n &gt; 0, only the lower n bits of the address will change. This wraps the address on a (1 &lt;&lt; n) byte boundary, facilitating access to naturally-aligned ring buffers.\n\n
RING_SIZE: u4 = 0,
/// RING_SEL [10:10]
/// Select whether RING_SIZE applies to read or write addresses.\n
RING_SEL: u1 = 0,
/// CHAIN_TO [11:14]
/// When this channel completes, it will trigger the channel indicated by CHAIN_TO. Disable by setting CHAIN_TO = _(this channel)_.\n
CHAIN_TO: u4 = 11,
/// TREQ_SEL [15:20]
/// Select a Transfer Request signal.\n
TREQ_SEL: u6 = 0,
/// IRQ_QUIET [21:21]
/// In QUIET mode, the channel does not generate IRQs at the end of every transfer block. Instead, an IRQ is raised when NULL is written to a trigger register, indicating the end of a control block chain.\n\n
IRQ_QUIET: u1 = 0,
/// BSWAP [22:22]
/// Apply byte-swap transformation to DMA data.\n
BSWAP: u1 = 0,
/// SNIFF_EN [23:23]
/// If 1, this channel's data transfers are visible to the sniff hardware, and each transfer will advance the state of the checksum. This only applies if the sniff hardware is enabled, and has this channel selected.\n\n
SNIFF_EN: u1 = 0,
/// BUSY [24:24]
/// This flag goes high when the channel starts a new transfer sequence, and low when the last transfer of that sequence completes. Clearing EN while BUSY is high pauses the channel, and BUSY will stay high while paused.\n\n
BUSY: u1 = 0,
/// unused [25:28]
_unused25: u4 = 0,
/// WRITE_ERROR [29:29]
/// If 1, the channel received a write bus error. Write one to clear.\n
WRITE_ERROR: u1 = 0,
/// READ_ERROR [30:30]
/// If 1, the channel received a read bus error. Write one to clear.\n
READ_ERROR: u1 = 0,
/// AHB_ERROR [31:31]
/// Logical OR of the READ_ERROR and WRITE_ERROR flags. The channel halts when it encounters any bus error, and always raises its channel IRQ flag.
AHB_ERROR: u1 = 0,
};
/// DMA Channel 11 Control and Status
pub const CH11_CTRL_TRIG = Register(CH11_CTRL_TRIG_val).init(base_address + 0x2cc);

/// CH11_TRANS_COUNT
const CH11_TRANS_COUNT_val = packed struct {
CH11_TRANS_COUNT_0: u8 = 0,
CH11_TRANS_COUNT_1: u8 = 0,
CH11_TRANS_COUNT_2: u8 = 0,
CH11_TRANS_COUNT_3: u8 = 0,
};
/// DMA Channel 11 Transfer Count\n
pub const CH11_TRANS_COUNT = Register(CH11_TRANS_COUNT_val).init(base_address + 0x2c8);

/// CH11_WRITE_ADDR
const CH11_WRITE_ADDR_val = packed struct {
CH11_WRITE_ADDR_0: u8 = 0,
CH11_WRITE_ADDR_1: u8 = 0,
CH11_WRITE_ADDR_2: u8 = 0,
CH11_WRITE_ADDR_3: u8 = 0,
};
/// DMA Channel 11 Write Address pointer\n
pub const CH11_WRITE_ADDR = Register(CH11_WRITE_ADDR_val).init(base_address + 0x2c4);

/// CH11_READ_ADDR
const CH11_READ_ADDR_val = packed struct {
CH11_READ_ADDR_0: u8 = 0,
CH11_READ_ADDR_1: u8 = 0,
CH11_READ_ADDR_2: u8 = 0,
CH11_READ_ADDR_3: u8 = 0,
};
/// DMA Channel 11 Read Address pointer\n
pub const CH11_READ_ADDR = Register(CH11_READ_ADDR_val).init(base_address + 0x2c0);

/// CH10_AL3_READ_ADDR_TRIG
const CH10_AL3_READ_ADDR_TRIG_val = packed struct {
CH10_AL3_READ_ADDR_TRIG_0: u8 = 0,
CH10_AL3_READ_ADDR_TRIG_1: u8 = 0,
CH10_AL3_READ_ADDR_TRIG_2: u8 = 0,
CH10_AL3_READ_ADDR_TRIG_3: u8 = 0,
};
/// Alias for channel 10 READ_ADDR register\n
pub const CH10_AL3_READ_ADDR_TRIG = Register(CH10_AL3_READ_ADDR_TRIG_val).init(base_address + 0x2bc);

/// CH10_AL3_TRANS_COUNT
const CH10_AL3_TRANS_COUNT_val = packed struct {
CH10_AL3_TRANS_COUNT_0: u8 = 0,
CH10_AL3_TRANS_COUNT_1: u8 = 0,
CH10_AL3_TRANS_COUNT_2: u8 = 0,
CH10_AL3_TRANS_COUNT_3: u8 = 0,
};
/// Alias for channel 10 TRANS_COUNT register
pub const CH10_AL3_TRANS_COUNT = Register(CH10_AL3_TRANS_COUNT_val).init(base_address + 0x2b8);

/// CH10_AL3_WRITE_ADDR
const CH10_AL3_WRITE_ADDR_val = packed struct {
CH10_AL3_WRITE_ADDR_0: u8 = 0,
CH10_AL3_WRITE_ADDR_1: u8 = 0,
CH10_AL3_WRITE_ADDR_2: u8 = 0,
CH10_AL3_WRITE_ADDR_3: u8 = 0,
};
/// Alias for channel 10 WRITE_ADDR register
pub const CH10_AL3_WRITE_ADDR = Register(CH10_AL3_WRITE_ADDR_val).init(base_address + 0x2b4);

/// CH10_AL3_CTRL
const CH10_AL3_CTRL_val = packed struct {
CH10_AL3_CTRL_0: u8 = 0,
CH10_AL3_CTRL_1: u8 = 0,
CH10_AL3_CTRL_2: u8 = 0,
CH10_AL3_CTRL_3: u8 = 0,
};
/// Alias for channel 10 CTRL register
pub const CH10_AL3_CTRL = Register(CH10_AL3_CTRL_val).init(base_address + 0x2b0);

/// CH10_AL2_WRITE_ADDR_TRIG
const CH10_AL2_WRITE_ADDR_TRIG_val = packed struct {
CH10_AL2_WRITE_ADDR_TRIG_0: u8 = 0,
CH10_AL2_WRITE_ADDR_TRIG_1: u8 = 0,
CH10_AL2_WRITE_ADDR_TRIG_2: u8 = 0,
CH10_AL2_WRITE_ADDR_TRIG_3: u8 = 0,
};
/// Alias for channel 10 WRITE_ADDR register\n
pub const CH10_AL2_WRITE_ADDR_TRIG = Register(CH10_AL2_WRITE_ADDR_TRIG_val).init(base_address + 0x2ac);

/// CH10_AL2_READ_ADDR
const CH10_AL2_READ_ADDR_val = packed struct {
CH10_AL2_READ_ADDR_0: u8 = 0,
CH10_AL2_READ_ADDR_1: u8 = 0,
CH10_AL2_READ_ADDR_2: u8 = 0,
CH10_AL2_READ_ADDR_3: u8 = 0,
};
/// Alias for channel 10 READ_ADDR register
pub const CH10_AL2_READ_ADDR = Register(CH10_AL2_READ_ADDR_val).init(base_address + 0x2a8);

/// CH10_AL2_TRANS_COUNT
const CH10_AL2_TRANS_COUNT_val = packed struct {
CH10_AL2_TRANS_COUNT_0: u8 = 0,
CH10_AL2_TRANS_COUNT_1: u8 = 0,
CH10_AL2_TRANS_COUNT_2: u8 = 0,
CH10_AL2_TRANS_COUNT_3: u8 = 0,
};
/// Alias for channel 10 TRANS_COUNT register
pub const CH10_AL2_TRANS_COUNT = Register(CH10_AL2_TRANS_COUNT_val).init(base_address + 0x2a4);

/// CH10_AL2_CTRL
const CH10_AL2_CTRL_val = packed struct {
CH10_AL2_CTRL_0: u8 = 0,
CH10_AL2_CTRL_1: u8 = 0,
CH10_AL2_CTRL_2: u8 = 0,
CH10_AL2_CTRL_3: u8 = 0,
};
/// Alias for channel 10 CTRL register
pub const CH10_AL2_CTRL = Register(CH10_AL2_CTRL_val).init(base_address + 0x2a0);

/// CH10_AL1_TRANS_COUNT_TRIG
const CH10_AL1_TRANS_COUNT_TRIG_val = packed struct {
CH10_AL1_TRANS_COUNT_TRIG_0: u8 = 0,
CH10_AL1_TRANS_COUNT_TRIG_1: u8 = 0,
CH10_AL1_TRANS_COUNT_TRIG_2: u8 = 0,
CH10_AL1_TRANS_COUNT_TRIG_3: u8 = 0,
};
/// Alias for channel 10 TRANS_COUNT register\n
pub const CH10_AL1_TRANS_COUNT_TRIG = Register(CH10_AL1_TRANS_COUNT_TRIG_val).init(base_address + 0x29c);

/// CH10_AL1_WRITE_ADDR
const CH10_AL1_WRITE_ADDR_val = packed struct {
CH10_AL1_WRITE_ADDR_0: u8 = 0,
CH10_AL1_WRITE_ADDR_1: u8 = 0,
CH10_AL1_WRITE_ADDR_2: u8 = 0,
CH10_AL1_WRITE_ADDR_3: u8 = 0,
};
/// Alias for channel 10 WRITE_ADDR register
pub const CH10_AL1_WRITE_ADDR = Register(CH10_AL1_WRITE_ADDR_val).init(base_address + 0x298);

/// CH10_AL1_READ_ADDR
const CH10_AL1_READ_ADDR_val = packed struct {
CH10_AL1_READ_ADDR_0: u8 = 0,
CH10_AL1_READ_ADDR_1: u8 = 0,
CH10_AL1_READ_ADDR_2: u8 = 0,
CH10_AL1_READ_ADDR_3: u8 = 0,
};
/// Alias for channel 10 READ_ADDR register
pub const CH10_AL1_READ_ADDR = Register(CH10_AL1_READ_ADDR_val).init(base_address + 0x294);

/// CH10_AL1_CTRL
const CH10_AL1_CTRL_val = packed struct {
CH10_AL1_CTRL_0: u8 = 0,
CH10_AL1_CTRL_1: u8 = 0,
CH10_AL1_CTRL_2: u8 = 0,
CH10_AL1_CTRL_3: u8 = 0,
};
/// Alias for channel 10 CTRL register
pub const CH10_AL1_CTRL = Register(CH10_AL1_CTRL_val).init(base_address + 0x290);

/// CH10_CTRL_TRIG
const CH10_CTRL_TRIG_val = packed struct {
/// EN [0:0]
/// DMA Channel Enable.\n
EN: u1 = 0,
/// HIGH_PRIORITY [1:1]
/// HIGH_PRIORITY gives a channel preferential treatment in issue scheduling: in each scheduling round, all high priority channels are considered first, and then only a single low priority channel, before returning to the high priority channels.\n\n
HIGH_PRIORITY: u1 = 0,
/// DATA_SIZE [2:3]
/// Set the size of each bus transfer (byte/halfword/word). READ_ADDR and WRITE_ADDR advance by this amount (1/2/4 bytes) with each transfer.
DATA_SIZE: u2 = 0,
/// INCR_READ [4:4]
/// If 1, the read address increments with each transfer. If 0, each read is directed to the same, initial address.\n\n
INCR_READ: u1 = 0,
/// INCR_WRITE [5:5]
/// If 1, the write address increments with each transfer. If 0, each write is directed to the same, initial address.\n\n
INCR_WRITE: u1 = 0,
/// RING_SIZE [6:9]
/// Size of address wrap region. If 0, don't wrap. For values n &gt; 0, only the lower n bits of the address will change. This wraps the address on a (1 &lt;&lt; n) byte boundary, facilitating access to naturally-aligned ring buffers.\n\n
RING_SIZE: u4 = 0,
/// RING_SEL [10:10]
/// Select whether RING_SIZE applies to read or write addresses.\n
RING_SEL: u1 = 0,
/// CHAIN_TO [11:14]
/// When this channel completes, it will trigger the channel indicated by CHAIN_TO. Disable by setting CHAIN_TO = _(this channel)_.\n
CHAIN_TO: u4 = 10,
/// TREQ_SEL [15:20]
/// Select a Transfer Request signal.\n
TREQ_SEL: u6 = 0,
/// IRQ_QUIET [21:21]
/// In QUIET mode, the channel does not generate IRQs at the end of every transfer block. Instead, an IRQ is raised when NULL is written to a trigger register, indicating the end of a control block chain.\n\n
IRQ_QUIET: u1 = 0,
/// BSWAP [22:22]
/// Apply byte-swap transformation to DMA data.\n
BSWAP: u1 = 0,
/// SNIFF_EN [23:23]
/// If 1, this channel's data transfers are visible to the sniff hardware, and each transfer will advance the state of the checksum. This only applies if the sniff hardware is enabled, and has this channel selected.\n\n
SNIFF_EN: u1 = 0,
/// BUSY [24:24]
/// This flag goes high when the channel starts a new transfer sequence, and low when the last transfer of that sequence completes. Clearing EN while BUSY is high pauses the channel, and BUSY will stay high while paused.\n\n
BUSY: u1 = 0,
/// unused [25:28]
_unused25: u4 = 0,
/// WRITE_ERROR [29:29]
/// If 1, the channel received a write bus error. Write one to clear.\n
WRITE_ERROR: u1 = 0,
/// READ_ERROR [30:30]
/// If 1, the channel received a read bus error. Write one to clear.\n
READ_ERROR: u1 = 0,
/// AHB_ERROR [31:31]
/// Logical OR of the READ_ERROR and WRITE_ERROR flags. The channel halts when it encounters any bus error, and always raises its channel IRQ flag.
AHB_ERROR: u1 = 0,
};
/// DMA Channel 10 Control and Status
pub const CH10_CTRL_TRIG = Register(CH10_CTRL_TRIG_val).init(base_address + 0x28c);

/// CH10_TRANS_COUNT
const CH10_TRANS_COUNT_val = packed struct {
CH10_TRANS_COUNT_0: u8 = 0,
CH10_TRANS_COUNT_1: u8 = 0,
CH10_TRANS_COUNT_2: u8 = 0,
CH10_TRANS_COUNT_3: u8 = 0,
};
/// DMA Channel 10 Transfer Count\n
pub const CH10_TRANS_COUNT = Register(CH10_TRANS_COUNT_val).init(base_address + 0x288);

/// CH10_WRITE_ADDR
const CH10_WRITE_ADDR_val = packed struct {
CH10_WRITE_ADDR_0: u8 = 0,
CH10_WRITE_ADDR_1: u8 = 0,
CH10_WRITE_ADDR_2: u8 = 0,
CH10_WRITE_ADDR_3: u8 = 0,
};
/// DMA Channel 10 Write Address pointer\n
pub const CH10_WRITE_ADDR = Register(CH10_WRITE_ADDR_val).init(base_address + 0x284);

/// CH10_READ_ADDR
const CH10_READ_ADDR_val = packed struct {
CH10_READ_ADDR_0: u8 = 0,
CH10_READ_ADDR_1: u8 = 0,
CH10_READ_ADDR_2: u8 = 0,
CH10_READ_ADDR_3: u8 = 0,
};
/// DMA Channel 10 Read Address pointer\n
pub const CH10_READ_ADDR = Register(CH10_READ_ADDR_val).init(base_address + 0x280);

/// CH9_AL3_READ_ADDR_TRIG
const CH9_AL3_READ_ADDR_TRIG_val = packed struct {
CH9_AL3_READ_ADDR_TRIG_0: u8 = 0,
CH9_AL3_READ_ADDR_TRIG_1: u8 = 0,
CH9_AL3_READ_ADDR_TRIG_2: u8 = 0,
CH9_AL3_READ_ADDR_TRIG_3: u8 = 0,
};
/// Alias for channel 9 READ_ADDR register\n
pub const CH9_AL3_READ_ADDR_TRIG = Register(CH9_AL3_READ_ADDR_TRIG_val).init(base_address + 0x27c);

/// CH9_AL3_TRANS_COUNT
const CH9_AL3_TRANS_COUNT_val = packed struct {
CH9_AL3_TRANS_COUNT_0: u8 = 0,
CH9_AL3_TRANS_COUNT_1: u8 = 0,
CH9_AL3_TRANS_COUNT_2: u8 = 0,
CH9_AL3_TRANS_COUNT_3: u8 = 0,
};
/// Alias for channel 9 TRANS_COUNT register
pub const CH9_AL3_TRANS_COUNT = Register(CH9_AL3_TRANS_COUNT_val).init(base_address + 0x278);

/// CH9_AL3_WRITE_ADDR
const CH9_AL3_WRITE_ADDR_val = packed struct {
CH9_AL3_WRITE_ADDR_0: u8 = 0,
CH9_AL3_WRITE_ADDR_1: u8 = 0,
CH9_AL3_WRITE_ADDR_2: u8 = 0,
CH9_AL3_WRITE_ADDR_3: u8 = 0,
};
/// Alias for channel 9 WRITE_ADDR register
pub const CH9_AL3_WRITE_ADDR = Register(CH9_AL3_WRITE_ADDR_val).init(base_address + 0x274);

/// CH9_AL3_CTRL
const CH9_AL3_CTRL_val = packed struct {
CH9_AL3_CTRL_0: u8 = 0,
CH9_AL3_CTRL_1: u8 = 0,
CH9_AL3_CTRL_2: u8 = 0,
CH9_AL3_CTRL_3: u8 = 0,
};
/// Alias for channel 9 CTRL register
pub const CH9_AL3_CTRL = Register(CH9_AL3_CTRL_val).init(base_address + 0x270);

/// CH9_AL2_WRITE_ADDR_TRIG
const CH9_AL2_WRITE_ADDR_TRIG_val = packed struct {
CH9_AL2_WRITE_ADDR_TRIG_0: u8 = 0,
CH9_AL2_WRITE_ADDR_TRIG_1: u8 = 0,
CH9_AL2_WRITE_ADDR_TRIG_2: u8 = 0,
CH9_AL2_WRITE_ADDR_TRIG_3: u8 = 0,
};
/// Alias for channel 9 WRITE_ADDR register\n
pub const CH9_AL2_WRITE_ADDR_TRIG = Register(CH9_AL2_WRITE_ADDR_TRIG_val).init(base_address + 0x26c);

/// CH9_AL2_READ_ADDR
const CH9_AL2_READ_ADDR_val = packed struct {
CH9_AL2_READ_ADDR_0: u8 = 0,
CH9_AL2_READ_ADDR_1: u8 = 0,
CH9_AL2_READ_ADDR_2: u8 = 0,
CH9_AL2_READ_ADDR_3: u8 = 0,
};
/// Alias for channel 9 READ_ADDR register
pub const CH9_AL2_READ_ADDR = Register(CH9_AL2_READ_ADDR_val).init(base_address + 0x268);

/// CH9_AL2_TRANS_COUNT
const CH9_AL2_TRANS_COUNT_val = packed struct {
CH9_AL2_TRANS_COUNT_0: u8 = 0,
CH9_AL2_TRANS_COUNT_1: u8 = 0,
CH9_AL2_TRANS_COUNT_2: u8 = 0,
CH9_AL2_TRANS_COUNT_3: u8 = 0,
};
/// Alias for channel 9 TRANS_COUNT register
pub const CH9_AL2_TRANS_COUNT = Register(CH9_AL2_TRANS_COUNT_val).init(base_address + 0x264);

/// CH9_AL2_CTRL
const CH9_AL2_CTRL_val = packed struct {
CH9_AL2_CTRL_0: u8 = 0,
CH9_AL2_CTRL_1: u8 = 0,
CH9_AL2_CTRL_2: u8 = 0,
CH9_AL2_CTRL_3: u8 = 0,
};
/// Alias for channel 9 CTRL register
pub const CH9_AL2_CTRL = Register(CH9_AL2_CTRL_val).init(base_address + 0x260);

/// CH9_AL1_TRANS_COUNT_TRIG
const CH9_AL1_TRANS_COUNT_TRIG_val = packed struct {
CH9_AL1_TRANS_COUNT_TRIG_0: u8 = 0,
CH9_AL1_TRANS_COUNT_TRIG_1: u8 = 0,
CH9_AL1_TRANS_COUNT_TRIG_2: u8 = 0,
CH9_AL1_TRANS_COUNT_TRIG_3: u8 = 0,
};
/// Alias for channel 9 TRANS_COUNT register\n
pub const CH9_AL1_TRANS_COUNT_TRIG = Register(CH9_AL1_TRANS_COUNT_TRIG_val).init(base_address + 0x25c);

/// CH9_AL1_WRITE_ADDR
const CH9_AL1_WRITE_ADDR_val = packed struct {
CH9_AL1_WRITE_ADDR_0: u8 = 0,
CH9_AL1_WRITE_ADDR_1: u8 = 0,
CH9_AL1_WRITE_ADDR_2: u8 = 0,
CH9_AL1_WRITE_ADDR_3: u8 = 0,
};
/// Alias for channel 9 WRITE_ADDR register
pub const CH9_AL1_WRITE_ADDR = Register(CH9_AL1_WRITE_ADDR_val).init(base_address + 0x258);

/// CH9_AL1_READ_ADDR
const CH9_AL1_READ_ADDR_val = packed struct {
CH9_AL1_READ_ADDR_0: u8 = 0,
CH9_AL1_READ_ADDR_1: u8 = 0,
CH9_AL1_READ_ADDR_2: u8 = 0,
CH9_AL1_READ_ADDR_3: u8 = 0,
};
/// Alias for channel 9 READ_ADDR register
pub const CH9_AL1_READ_ADDR = Register(CH9_AL1_READ_ADDR_val).init(base_address + 0x254);

/// CH9_AL1_CTRL
const CH9_AL1_CTRL_val = packed struct {
CH9_AL1_CTRL_0: u8 = 0,
CH9_AL1_CTRL_1: u8 = 0,
CH9_AL1_CTRL_2: u8 = 0,
CH9_AL1_CTRL_3: u8 = 0,
};
/// Alias for channel 9 CTRL register
pub const CH9_AL1_CTRL = Register(CH9_AL1_CTRL_val).init(base_address + 0x250);

/// CH9_CTRL_TRIG
const CH9_CTRL_TRIG_val = packed struct {
/// EN [0:0]
/// DMA Channel Enable.\n
EN: u1 = 0,
/// HIGH_PRIORITY [1:1]
/// HIGH_PRIORITY gives a channel preferential treatment in issue scheduling: in each scheduling round, all high priority channels are considered first, and then only a single low priority channel, before returning to the high priority channels.\n\n
HIGH_PRIORITY: u1 = 0,
/// DATA_SIZE [2:3]
/// Set the size of each bus transfer (byte/halfword/word). READ_ADDR and WRITE_ADDR advance by this amount (1/2/4 bytes) with each transfer.
DATA_SIZE: u2 = 0,
/// INCR_READ [4:4]
/// If 1, the read address increments with each transfer. If 0, each read is directed to the same, initial address.\n\n
INCR_READ: u1 = 0,
/// INCR_WRITE [5:5]
/// If 1, the write address increments with each transfer. If 0, each write is directed to the same, initial address.\n\n
INCR_WRITE: u1 = 0,
/// RING_SIZE [6:9]
/// Size of address wrap region. If 0, don't wrap. For values n &gt; 0, only the lower n bits of the address will change. This wraps the address on a (1 &lt;&lt; n) byte boundary, facilitating access to naturally-aligned ring buffers.\n\n
RING_SIZE: u4 = 0,
/// RING_SEL [10:10]
/// Select whether RING_SIZE applies to read or write addresses.\n
RING_SEL: u1 = 0,
/// CHAIN_TO [11:14]
/// When this channel completes, it will trigger the channel indicated by CHAIN_TO. Disable by setting CHAIN_TO = _(this channel)_.\n
CHAIN_TO: u4 = 9,
/// TREQ_SEL [15:20]
/// Select a Transfer Request signal.\n
TREQ_SEL: u6 = 0,
/// IRQ_QUIET [21:21]
/// In QUIET mode, the channel does not generate IRQs at the end of every transfer block. Instead, an IRQ is raised when NULL is written to a trigger register, indicating the end of a control block chain.\n\n
IRQ_QUIET: u1 = 0,
/// BSWAP [22:22]
/// Apply byte-swap transformation to DMA data.\n
BSWAP: u1 = 0,
/// SNIFF_EN [23:23]
/// If 1, this channel's data transfers are visible to the sniff hardware, and each transfer will advance the state of the checksum. This only applies if the sniff hardware is enabled, and has this channel selected.\n\n
SNIFF_EN: u1 = 0,
/// BUSY [24:24]
/// This flag goes high when the channel starts a new transfer sequence, and low when the last transfer of that sequence completes. Clearing EN while BUSY is high pauses the channel, and BUSY will stay high while paused.\n\n
BUSY: u1 = 0,
/// unused [25:28]
_unused25: u4 = 0,
/// WRITE_ERROR [29:29]
/// If 1, the channel received a write bus error. Write one to clear.\n
WRITE_ERROR: u1 = 0,
/// READ_ERROR [30:30]
/// If 1, the channel received a read bus error. Write one to clear.\n
READ_ERROR: u1 = 0,
/// AHB_ERROR [31:31]
/// Logical OR of the READ_ERROR and WRITE_ERROR flags. The channel halts when it encounters any bus error, and always raises its channel IRQ flag.
AHB_ERROR: u1 = 0,
};
/// DMA Channel 9 Control and Status
pub const CH9_CTRL_TRIG = Register(CH9_CTRL_TRIG_val).init(base_address + 0x24c);

/// CH9_TRANS_COUNT
const CH9_TRANS_COUNT_val = packed struct {
CH9_TRANS_COUNT_0: u8 = 0,
CH9_TRANS_COUNT_1: u8 = 0,
CH9_TRANS_COUNT_2: u8 = 0,
CH9_TRANS_COUNT_3: u8 = 0,
};
/// DMA Channel 9 Transfer Count\n
pub const CH9_TRANS_COUNT = Register(CH9_TRANS_COUNT_val).init(base_address + 0x248);

/// CH9_WRITE_ADDR
const CH9_WRITE_ADDR_val = packed struct {
CH9_WRITE_ADDR_0: u8 = 0,
CH9_WRITE_ADDR_1: u8 = 0,
CH9_WRITE_ADDR_2: u8 = 0,
CH9_WRITE_ADDR_3: u8 = 0,
};
/// DMA Channel 9 Write Address pointer\n
pub const CH9_WRITE_ADDR = Register(CH9_WRITE_ADDR_val).init(base_address + 0x244);

/// CH9_READ_ADDR
const CH9_READ_ADDR_val = packed struct {
CH9_READ_ADDR_0: u8 = 0,
CH9_READ_ADDR_1: u8 = 0,
CH9_READ_ADDR_2: u8 = 0,
CH9_READ_ADDR_3: u8 = 0,
};
/// DMA Channel 9 Read Address pointer\n
pub const CH9_READ_ADDR = Register(CH9_READ_ADDR_val).init(base_address + 0x240);

/// CH8_AL3_READ_ADDR_TRIG
const CH8_AL3_READ_ADDR_TRIG_val = packed struct {
CH8_AL3_READ_ADDR_TRIG_0: u8 = 0,
CH8_AL3_READ_ADDR_TRIG_1: u8 = 0,
CH8_AL3_READ_ADDR_TRIG_2: u8 = 0,
CH8_AL3_READ_ADDR_TRIG_3: u8 = 0,
};
/// Alias for channel 8 READ_ADDR register\n
pub const CH8_AL3_READ_ADDR_TRIG = Register(CH8_AL3_READ_ADDR_TRIG_val).init(base_address + 0x23c);

/// CH8_AL3_TRANS_COUNT
const CH8_AL3_TRANS_COUNT_val = packed struct {
CH8_AL3_TRANS_COUNT_0: u8 = 0,
CH8_AL3_TRANS_COUNT_1: u8 = 0,
CH8_AL3_TRANS_COUNT_2: u8 = 0,
CH8_AL3_TRANS_COUNT_3: u8 = 0,
};
/// Alias for channel 8 TRANS_COUNT register
pub const CH8_AL3_TRANS_COUNT = Register(CH8_AL3_TRANS_COUNT_val).init(base_address + 0x238);

/// CH8_AL3_WRITE_ADDR
const CH8_AL3_WRITE_ADDR_val = packed struct {
CH8_AL3_WRITE_ADDR_0: u8 = 0,
CH8_AL3_WRITE_ADDR_1: u8 = 0,
CH8_AL3_WRITE_ADDR_2: u8 = 0,
CH8_AL3_WRITE_ADDR_3: u8 = 0,
};
/// Alias for channel 8 WRITE_ADDR register
pub const CH8_AL3_WRITE_ADDR = Register(CH8_AL3_WRITE_ADDR_val).init(base_address + 0x234);

/// CH8_AL3_CTRL
const CH8_AL3_CTRL_val = packed struct {
CH8_AL3_CTRL_0: u8 = 0,
CH8_AL3_CTRL_1: u8 = 0,
CH8_AL3_CTRL_2: u8 = 0,
CH8_AL3_CTRL_3: u8 = 0,
};
/// Alias for channel 8 CTRL register
pub const CH8_AL3_CTRL = Register(CH8_AL3_CTRL_val).init(base_address + 0x230);

/// CH8_AL2_WRITE_ADDR_TRIG
const CH8_AL2_WRITE_ADDR_TRIG_val = packed struct {
CH8_AL2_WRITE_ADDR_TRIG_0: u8 = 0,
CH8_AL2_WRITE_ADDR_TRIG_1: u8 = 0,
CH8_AL2_WRITE_ADDR_TRIG_2: u8 = 0,
CH8_AL2_WRITE_ADDR_TRIG_3: u8 = 0,
};
/// Alias for channel 8 WRITE_ADDR register\n
pub const CH8_AL2_WRITE_ADDR_TRIG = Register(CH8_AL2_WRITE_ADDR_TRIG_val).init(base_address + 0x22c);

/// CH8_AL2_READ_ADDR
const CH8_AL2_READ_ADDR_val = packed struct {
CH8_AL2_READ_ADDR_0: u8 = 0,
CH8_AL2_READ_ADDR_1: u8 = 0,
CH8_AL2_READ_ADDR_2: u8 = 0,
CH8_AL2_READ_ADDR_3: u8 = 0,
};
/// Alias for channel 8 READ_ADDR register
pub const CH8_AL2_READ_ADDR = Register(CH8_AL2_READ_ADDR_val).init(base_address + 0x228);

/// CH8_AL2_TRANS_COUNT
const CH8_AL2_TRANS_COUNT_val = packed struct {
CH8_AL2_TRANS_COUNT_0: u8 = 0,
CH8_AL2_TRANS_COUNT_1: u8 = 0,
CH8_AL2_TRANS_COUNT_2: u8 = 0,
CH8_AL2_TRANS_COUNT_3: u8 = 0,
};
/// Alias for channel 8 TRANS_COUNT register
pub const CH8_AL2_TRANS_COUNT = Register(CH8_AL2_TRANS_COUNT_val).init(base_address + 0x224);

/// CH8_AL2_CTRL
const CH8_AL2_CTRL_val = packed struct {
CH8_AL2_CTRL_0: u8 = 0,
CH8_AL2_CTRL_1: u8 = 0,
CH8_AL2_CTRL_2: u8 = 0,
CH8_AL2_CTRL_3: u8 = 0,
};
/// Alias for channel 8 CTRL register
pub const CH8_AL2_CTRL = Register(CH8_AL2_CTRL_val).init(base_address + 0x220);

/// CH8_AL1_TRANS_COUNT_TRIG
const CH8_AL1_TRANS_COUNT_TRIG_val = packed struct {
CH8_AL1_TRANS_COUNT_TRIG_0: u8 = 0,
CH8_AL1_TRANS_COUNT_TRIG_1: u8 = 0,
CH8_AL1_TRANS_COUNT_TRIG_2: u8 = 0,
CH8_AL1_TRANS_COUNT_TRIG_3: u8 = 0,
};
/// Alias for channel 8 TRANS_COUNT register\n
pub const CH8_AL1_TRANS_COUNT_TRIG = Register(CH8_AL1_TRANS_COUNT_TRIG_val).init(base_address + 0x21c);

/// CH8_AL1_WRITE_ADDR
const CH8_AL1_WRITE_ADDR_val = packed struct {
CH8_AL1_WRITE_ADDR_0: u8 = 0,
CH8_AL1_WRITE_ADDR_1: u8 = 0,
CH8_AL1_WRITE_ADDR_2: u8 = 0,
CH8_AL1_WRITE_ADDR_3: u8 = 0,
};
/// Alias for channel 8 WRITE_ADDR register
pub const CH8_AL1_WRITE_ADDR = Register(CH8_AL1_WRITE_ADDR_val).init(base_address + 0x218);

/// CH8_AL1_READ_ADDR
const CH8_AL1_READ_ADDR_val = packed struct {
CH8_AL1_READ_ADDR_0: u8 = 0,
CH8_AL1_READ_ADDR_1: u8 = 0,
CH8_AL1_READ_ADDR_2: u8 = 0,
CH8_AL1_READ_ADDR_3: u8 = 0,
};
/// Alias for channel 8 READ_ADDR register
pub const CH8_AL1_READ_ADDR = Register(CH8_AL1_READ_ADDR_val).init(base_address + 0x214);

/// CH8_AL1_CTRL
const CH8_AL1_CTRL_val = packed struct {
CH8_AL1_CTRL_0: u8 = 0,
CH8_AL1_CTRL_1: u8 = 0,
CH8_AL1_CTRL_2: u8 = 0,
CH8_AL1_CTRL_3: u8 = 0,
};
/// Alias for channel 8 CTRL register
pub const CH8_AL1_CTRL = Register(CH8_AL1_CTRL_val).init(base_address + 0x210);

/// CH8_CTRL_TRIG
const CH8_CTRL_TRIG_val = packed struct {
/// EN [0:0]
/// DMA Channel Enable.\n
EN: u1 = 0,
/// HIGH_PRIORITY [1:1]
/// HIGH_PRIORITY gives a channel preferential treatment in issue scheduling: in each scheduling round, all high priority channels are considered first, and then only a single low priority channel, before returning to the high priority channels.\n\n
HIGH_PRIORITY: u1 = 0,
/// DATA_SIZE [2:3]
/// Set the size of each bus transfer (byte/halfword/word). READ_ADDR and WRITE_ADDR advance by this amount (1/2/4 bytes) with each transfer.
DATA_SIZE: u2 = 0,
/// INCR_READ [4:4]
/// If 1, the read address increments with each transfer. If 0, each read is directed to the same, initial address.\n\n
INCR_READ: u1 = 0,
/// INCR_WRITE [5:5]
/// If 1, the write address increments with each transfer. If 0, each write is directed to the same, initial address.\n\n
INCR_WRITE: u1 = 0,
/// RING_SIZE [6:9]
/// Size of address wrap region. If 0, don't wrap. For values n &gt; 0, only the lower n bits of the address will change. This wraps the address on a (1 &lt;&lt; n) byte boundary, facilitating access to naturally-aligned ring buffers.\n\n
RING_SIZE: u4 = 0,
/// RING_SEL [10:10]
/// Select whether RING_SIZE applies to read or write addresses.\n
RING_SEL: u1 = 0,
/// CHAIN_TO [11:14]
/// When this channel completes, it will trigger the channel indicated by CHAIN_TO. Disable by setting CHAIN_TO = _(this channel)_.\n
CHAIN_TO: u4 = 8,
/// TREQ_SEL [15:20]
/// Select a Transfer Request signal.\n
TREQ_SEL: u6 = 0,
/// IRQ_QUIET [21:21]
/// In QUIET mode, the channel does not generate IRQs at the end of every transfer block. Instead, an IRQ is raised when NULL is written to a trigger register, indicating the end of a control block chain.\n\n
IRQ_QUIET: u1 = 0,
/// BSWAP [22:22]
/// Apply byte-swap transformation to DMA data.\n
BSWAP: u1 = 0,
/// SNIFF_EN [23:23]
/// If 1, this channel's data transfers are visible to the sniff hardware, and each transfer will advance the state of the checksum. This only applies if the sniff hardware is enabled, and has this channel selected.\n\n
SNIFF_EN: u1 = 0,
/// BUSY [24:24]
/// This flag goes high when the channel starts a new transfer sequence, and low when the last transfer of that sequence completes. Clearing EN while BUSY is high pauses the channel, and BUSY will stay high while paused.\n\n
BUSY: u1 = 0,
/// unused [25:28]
_unused25: u4 = 0,
/// WRITE_ERROR [29:29]
/// If 1, the channel received a write bus error. Write one to clear.\n
WRITE_ERROR: u1 = 0,
/// READ_ERROR [30:30]
/// If 1, the channel received a read bus error. Write one to clear.\n
READ_ERROR: u1 = 0,
/// AHB_ERROR [31:31]
/// Logical OR of the READ_ERROR and WRITE_ERROR flags. The channel halts when it encounters any bus error, and always raises its channel IRQ flag.
AHB_ERROR: u1 = 0,
};
/// DMA Channel 8 Control and Status
pub const CH8_CTRL_TRIG = Register(CH8_CTRL_TRIG_val).init(base_address + 0x20c);

/// CH8_TRANS_COUNT
const CH8_TRANS_COUNT_val = packed struct {
CH8_TRANS_COUNT_0: u8 = 0,
CH8_TRANS_COUNT_1: u8 = 0,
CH8_TRANS_COUNT_2: u8 = 0,
CH8_TRANS_COUNT_3: u8 = 0,
};
/// DMA Channel 8 Transfer Count\n
pub const CH8_TRANS_COUNT = Register(CH8_TRANS_COUNT_val).init(base_address + 0x208);

/// CH8_WRITE_ADDR
const CH8_WRITE_ADDR_val = packed struct {
CH8_WRITE_ADDR_0: u8 = 0,
CH8_WRITE_ADDR_1: u8 = 0,
CH8_WRITE_ADDR_2: u8 = 0,
CH8_WRITE_ADDR_3: u8 = 0,
};
/// DMA Channel 8 Write Address pointer\n
pub const CH8_WRITE_ADDR = Register(CH8_WRITE_ADDR_val).init(base_address + 0x204);

/// CH8_READ_ADDR
const CH8_READ_ADDR_val = packed struct {
CH8_READ_ADDR_0: u8 = 0,
CH8_READ_ADDR_1: u8 = 0,
CH8_READ_ADDR_2: u8 = 0,
CH8_READ_ADDR_3: u8 = 0,
};
/// DMA Channel 8 Read Address pointer\n
pub const CH8_READ_ADDR = Register(CH8_READ_ADDR_val).init(base_address + 0x200);

/// CH7_AL3_READ_ADDR_TRIG
const CH7_AL3_READ_ADDR_TRIG_val = packed struct {
CH7_AL3_READ_ADDR_TRIG_0: u8 = 0,
CH7_AL3_READ_ADDR_TRIG_1: u8 = 0,
CH7_AL3_READ_ADDR_TRIG_2: u8 = 0,
CH7_AL3_READ_ADDR_TRIG_3: u8 = 0,
};
/// Alias for channel 7 READ_ADDR register\n
pub const CH7_AL3_READ_ADDR_TRIG = Register(CH7_AL3_READ_ADDR_TRIG_val).init(base_address + 0x1fc);

/// CH7_AL3_TRANS_COUNT
const CH7_AL3_TRANS_COUNT_val = packed struct {
CH7_AL3_TRANS_COUNT_0: u8 = 0,
CH7_AL3_TRANS_COUNT_1: u8 = 0,
CH7_AL3_TRANS_COUNT_2: u8 = 0,
CH7_AL3_TRANS_COUNT_3: u8 = 0,
};
/// Alias for channel 7 TRANS_COUNT register
pub const CH7_AL3_TRANS_COUNT = Register(CH7_AL3_TRANS_COUNT_val).init(base_address + 0x1f8);

/// CH7_AL3_WRITE_ADDR
const CH7_AL3_WRITE_ADDR_val = packed struct {
CH7_AL3_WRITE_ADDR_0: u8 = 0,
CH7_AL3_WRITE_ADDR_1: u8 = 0,
CH7_AL3_WRITE_ADDR_2: u8 = 0,
CH7_AL3_WRITE_ADDR_3: u8 = 0,
};
/// Alias for channel 7 WRITE_ADDR register
pub const CH7_AL3_WRITE_ADDR = Register(CH7_AL3_WRITE_ADDR_val).init(base_address + 0x1f4);

/// CH7_AL3_CTRL
const CH7_AL3_CTRL_val = packed struct {
CH7_AL3_CTRL_0: u8 = 0,
CH7_AL3_CTRL_1: u8 = 0,
CH7_AL3_CTRL_2: u8 = 0,
CH7_AL3_CTRL_3: u8 = 0,
};
/// Alias for channel 7 CTRL register
pub const CH7_AL3_CTRL = Register(CH7_AL3_CTRL_val).init(base_address + 0x1f0);

/// CH7_AL2_WRITE_ADDR_TRIG
const CH7_AL2_WRITE_ADDR_TRIG_val = packed struct {
CH7_AL2_WRITE_ADDR_TRIG_0: u8 = 0,
CH7_AL2_WRITE_ADDR_TRIG_1: u8 = 0,
CH7_AL2_WRITE_ADDR_TRIG_2: u8 = 0,
CH7_AL2_WRITE_ADDR_TRIG_3: u8 = 0,
};
/// Alias for channel 7 WRITE_ADDR register\n
pub const CH7_AL2_WRITE_ADDR_TRIG = Register(CH7_AL2_WRITE_ADDR_TRIG_val).init(base_address + 0x1ec);

/// CH7_AL2_READ_ADDR
const CH7_AL2_READ_ADDR_val = packed struct {
CH7_AL2_READ_ADDR_0: u8 = 0,
CH7_AL2_READ_ADDR_1: u8 = 0,
CH7_AL2_READ_ADDR_2: u8 = 0,
CH7_AL2_READ_ADDR_3: u8 = 0,
};
/// Alias for channel 7 READ_ADDR register
pub const CH7_AL2_READ_ADDR = Register(CH7_AL2_READ_ADDR_val).init(base_address + 0x1e8);

/// CH7_AL2_TRANS_COUNT
const CH7_AL2_TRANS_COUNT_val = packed struct {
CH7_AL2_TRANS_COUNT_0: u8 = 0,
CH7_AL2_TRANS_COUNT_1: u8 = 0,
CH7_AL2_TRANS_COUNT_2: u8 = 0,
CH7_AL2_TRANS_COUNT_3: u8 = 0,
};
/// Alias for channel 7 TRANS_COUNT register
pub const CH7_AL2_TRANS_COUNT = Register(CH7_AL2_TRANS_COUNT_val).init(base_address + 0x1e4);

/// CH7_AL2_CTRL
const CH7_AL2_CTRL_val = packed struct {
CH7_AL2_CTRL_0: u8 = 0,
CH7_AL2_CTRL_1: u8 = 0,
CH7_AL2_CTRL_2: u8 = 0,
CH7_AL2_CTRL_3: u8 = 0,
};
/// Alias for channel 7 CTRL register
pub const CH7_AL2_CTRL = Register(CH7_AL2_CTRL_val).init(base_address + 0x1e0);

/// CH7_AL1_TRANS_COUNT_TRIG
const CH7_AL1_TRANS_COUNT_TRIG_val = packed struct {
CH7_AL1_TRANS_COUNT_TRIG_0: u8 = 0,
CH7_AL1_TRANS_COUNT_TRIG_1: u8 = 0,
CH7_AL1_TRANS_COUNT_TRIG_2: u8 = 0,
CH7_AL1_TRANS_COUNT_TRIG_3: u8 = 0,
};
/// Alias for channel 7 TRANS_COUNT register\n
pub const CH7_AL1_TRANS_COUNT_TRIG = Register(CH7_AL1_TRANS_COUNT_TRIG_val).init(base_address + 0x1dc);

/// CH7_AL1_WRITE_ADDR
const CH7_AL1_WRITE_ADDR_val = packed struct {
CH7_AL1_WRITE_ADDR_0: u8 = 0,
CH7_AL1_WRITE_ADDR_1: u8 = 0,
CH7_AL1_WRITE_ADDR_2: u8 = 0,
CH7_AL1_WRITE_ADDR_3: u8 = 0,
};
/// Alias for channel 7 WRITE_ADDR register
pub const CH7_AL1_WRITE_ADDR = Register(CH7_AL1_WRITE_ADDR_val).init(base_address + 0x1d8);

/// CH7_AL1_READ_ADDR
const CH7_AL1_READ_ADDR_val = packed struct {
CH7_AL1_READ_ADDR_0: u8 = 0,
CH7_AL1_READ_ADDR_1: u8 = 0,
CH7_AL1_READ_ADDR_2: u8 = 0,
CH7_AL1_READ_ADDR_3: u8 = 0,
};
/// Alias for channel 7 READ_ADDR register
pub const CH7_AL1_READ_ADDR = Register(CH7_AL1_READ_ADDR_val).init(base_address + 0x1d4);

/// CH7_AL1_CTRL
const CH7_AL1_CTRL_val = packed struct {
CH7_AL1_CTRL_0: u8 = 0,
CH7_AL1_CTRL_1: u8 = 0,
CH7_AL1_CTRL_2: u8 = 0,
CH7_AL1_CTRL_3: u8 = 0,
};
/// Alias for channel 7 CTRL register
pub const CH7_AL1_CTRL = Register(CH7_AL1_CTRL_val).init(base_address + 0x1d0);

/// CH7_CTRL_TRIG
const CH7_CTRL_TRIG_val = packed struct {
/// EN [0:0]
/// DMA Channel Enable.\n
EN: u1 = 0,
/// HIGH_PRIORITY [1:1]
/// HIGH_PRIORITY gives a channel preferential treatment in issue scheduling: in each scheduling round, all high priority channels are considered first, and then only a single low priority channel, before returning to the high priority channels.\n\n
HIGH_PRIORITY: u1 = 0,
/// DATA_SIZE [2:3]
/// Set the size of each bus transfer (byte/halfword/word). READ_ADDR and WRITE_ADDR advance by this amount (1/2/4 bytes) with each transfer.
DATA_SIZE: u2 = 0,
/// INCR_READ [4:4]
/// If 1, the read address increments with each transfer. If 0, each read is directed to the same, initial address.\n\n
INCR_READ: u1 = 0,
/// INCR_WRITE [5:5]
/// If 1, the write address increments with each transfer. If 0, each write is directed to the same, initial address.\n\n
INCR_WRITE: u1 = 0,
/// RING_SIZE [6:9]
/// Size of address wrap region. If 0, don't wrap. For values n &gt; 0, only the lower n bits of the address will change. This wraps the address on a (1 &lt;&lt; n) byte boundary, facilitating access to naturally-aligned ring buffers.\n\n
RING_SIZE: u4 = 0,
/// RING_SEL [10:10]
/// Select whether RING_SIZE applies to read or write addresses.\n
RING_SEL: u1 = 0,
/// CHAIN_TO [11:14]
/// When this channel completes, it will trigger the channel indicated by CHAIN_TO. Disable by setting CHAIN_TO = _(this channel)_.\n
CHAIN_TO: u4 = 7,
/// TREQ_SEL [15:20]
/// Select a Transfer Request signal.\n
TREQ_SEL: u6 = 0,
/// IRQ_QUIET [21:21]
/// In QUIET mode, the channel does not generate IRQs at the end of every transfer block. Instead, an IRQ is raised when NULL is written to a trigger register, indicating the end of a control block chain.\n\n
IRQ_QUIET: u1 = 0,
/// BSWAP [22:22]
/// Apply byte-swap transformation to DMA data.\n
BSWAP: u1 = 0,
/// SNIFF_EN [23:23]
/// If 1, this channel's data transfers are visible to the sniff hardware, and each transfer will advance the state of the checksum. This only applies if the sniff hardware is enabled, and has this channel selected.\n\n
SNIFF_EN: u1 = 0,
/// BUSY [24:24]
/// This flag goes high when the channel starts a new transfer sequence, and low when the last transfer of that sequence completes. Clearing EN while BUSY is high pauses the channel, and BUSY will stay high while paused.\n\n
BUSY: u1 = 0,
/// unused [25:28]
_unused25: u4 = 0,
/// WRITE_ERROR [29:29]
/// If 1, the channel received a write bus error. Write one to clear.\n
WRITE_ERROR: u1 = 0,
/// READ_ERROR [30:30]
/// If 1, the channel received a read bus error. Write one to clear.\n
READ_ERROR: u1 = 0,
/// AHB_ERROR [31:31]
/// Logical OR of the READ_ERROR and WRITE_ERROR flags. The channel halts when it encounters any bus error, and always raises its channel IRQ flag.
AHB_ERROR: u1 = 0,
};
/// DMA Channel 7 Control and Status
pub const CH7_CTRL_TRIG = Register(CH7_CTRL_TRIG_val).init(base_address + 0x1cc);

/// CH7_TRANS_COUNT
const CH7_TRANS_COUNT_val = packed struct {
CH7_TRANS_COUNT_0: u8 = 0,
CH7_TRANS_COUNT_1: u8 = 0,
CH7_TRANS_COUNT_2: u8 = 0,
CH7_TRANS_COUNT_3: u8 = 0,
};
/// DMA Channel 7 Transfer Count\n
pub const CH7_TRANS_COUNT = Register(CH7_TRANS_COUNT_val).init(base_address + 0x1c8);

/// CH7_WRITE_ADDR
const CH7_WRITE_ADDR_val = packed struct {
CH7_WRITE_ADDR_0: u8 = 0,
CH7_WRITE_ADDR_1: u8 = 0,
CH7_WRITE_ADDR_2: u8 = 0,
CH7_WRITE_ADDR_3: u8 = 0,
};
/// DMA Channel 7 Write Address pointer\n
pub const CH7_WRITE_ADDR = Register(CH7_WRITE_ADDR_val).init(base_address + 0x1c4);

/// CH7_READ_ADDR
const CH7_READ_ADDR_val = packed struct {
CH7_READ_ADDR_0: u8 = 0,
CH7_READ_ADDR_1: u8 = 0,
CH7_READ_ADDR_2: u8 = 0,
CH7_READ_ADDR_3: u8 = 0,
};
/// DMA Channel 7 Read Address pointer\n
pub const CH7_READ_ADDR = Register(CH7_READ_ADDR_val).init(base_address + 0x1c0);

/// CH6_AL3_READ_ADDR_TRIG
const CH6_AL3_READ_ADDR_TRIG_val = packed struct {
CH6_AL3_READ_ADDR_TRIG_0: u8 = 0,
CH6_AL3_READ_ADDR_TRIG_1: u8 = 0,
CH6_AL3_READ_ADDR_TRIG_2: u8 = 0,
CH6_AL3_READ_ADDR_TRIG_3: u8 = 0,
};
/// Alias for channel 6 READ_ADDR register\n
pub const CH6_AL3_READ_ADDR_TRIG = Register(CH6_AL3_READ_ADDR_TRIG_val).init(base_address + 0x1bc);

/// CH6_AL3_TRANS_COUNT
const CH6_AL3_TRANS_COUNT_val = packed struct {
CH6_AL3_TRANS_COUNT_0: u8 = 0,
CH6_AL3_TRANS_COUNT_1: u8 = 0,
CH6_AL3_TRANS_COUNT_2: u8 = 0,
CH6_AL3_TRANS_COUNT_3: u8 = 0,
};
/// Alias for channel 6 TRANS_COUNT register
pub const CH6_AL3_TRANS_COUNT = Register(CH6_AL3_TRANS_COUNT_val).init(base_address + 0x1b8);

/// CH6_AL3_WRITE_ADDR
const CH6_AL3_WRITE_ADDR_val = packed struct {
CH6_AL3_WRITE_ADDR_0: u8 = 0,
CH6_AL3_WRITE_ADDR_1: u8 = 0,
CH6_AL3_WRITE_ADDR_2: u8 = 0,
CH6_AL3_WRITE_ADDR_3: u8 = 0,
};
/// Alias for channel 6 WRITE_ADDR register
pub const CH6_AL3_WRITE_ADDR = Register(CH6_AL3_WRITE_ADDR_val).init(base_address + 0x1b4);

/// CH6_AL3_CTRL
const CH6_AL3_CTRL_val = packed struct {
CH6_AL3_CTRL_0: u8 = 0,
CH6_AL3_CTRL_1: u8 = 0,
CH6_AL3_CTRL_2: u8 = 0,
CH6_AL3_CTRL_3: u8 = 0,
};
/// Alias for channel 6 CTRL register
pub const CH6_AL3_CTRL = Register(CH6_AL3_CTRL_val).init(base_address + 0x1b0);

/// CH6_AL2_WRITE_ADDR_TRIG
const CH6_AL2_WRITE_ADDR_TRIG_val = packed struct {
CH6_AL2_WRITE_ADDR_TRIG_0: u8 = 0,
CH6_AL2_WRITE_ADDR_TRIG_1: u8 = 0,
CH6_AL2_WRITE_ADDR_TRIG_2: u8 = 0,
CH6_AL2_WRITE_ADDR_TRIG_3: u8 = 0,
};
/// Alias for channel 6 WRITE_ADDR register\n
pub const CH6_AL2_WRITE_ADDR_TRIG = Register(CH6_AL2_WRITE_ADDR_TRIG_val).init(base_address + 0x1ac);

/// CH6_AL2_READ_ADDR
const CH6_AL2_READ_ADDR_val = packed struct {
CH6_AL2_READ_ADDR_0: u8 = 0,
CH6_AL2_READ_ADDR_1: u8 = 0,
CH6_AL2_READ_ADDR_2: u8 = 0,
CH6_AL2_READ_ADDR_3: u8 = 0,
};
/// Alias for channel 6 READ_ADDR register
pub const CH6_AL2_READ_ADDR = Register(CH6_AL2_READ_ADDR_val).init(base_address + 0x1a8);

/// CH6_AL2_TRANS_COUNT
const CH6_AL2_TRANS_COUNT_val = packed struct {
CH6_AL2_TRANS_COUNT_0: u8 = 0,
CH6_AL2_TRANS_COUNT_1: u8 = 0,
CH6_AL2_TRANS_COUNT_2: u8 = 0,
CH6_AL2_TRANS_COUNT_3: u8 = 0,
};
/// Alias for channel 6 TRANS_COUNT register
pub const CH6_AL2_TRANS_COUNT = Register(CH6_AL2_TRANS_COUNT_val).init(base_address + 0x1a4);

/// CH6_AL2_CTRL
const CH6_AL2_CTRL_val = packed struct {
CH6_AL2_CTRL_0: u8 = 0,
CH6_AL2_CTRL_1: u8 = 0,
CH6_AL2_CTRL_2: u8 = 0,
CH6_AL2_CTRL_3: u8 = 0,
};
/// Alias for channel 6 CTRL register
pub const CH6_AL2_CTRL = Register(CH6_AL2_CTRL_val).init(base_address + 0x1a0);

/// CH6_AL1_TRANS_COUNT_TRIG
const CH6_AL1_TRANS_COUNT_TRIG_val = packed struct {
CH6_AL1_TRANS_COUNT_TRIG_0: u8 = 0,
CH6_AL1_TRANS_COUNT_TRIG_1: u8 = 0,
CH6_AL1_TRANS_COUNT_TRIG_2: u8 = 0,
CH6_AL1_TRANS_COUNT_TRIG_3: u8 = 0,
};
/// Alias for channel 6 TRANS_COUNT register\n
pub const CH6_AL1_TRANS_COUNT_TRIG = Register(CH6_AL1_TRANS_COUNT_TRIG_val).init(base_address + 0x19c);

/// CH6_AL1_WRITE_ADDR
const CH6_AL1_WRITE_ADDR_val = packed struct {
CH6_AL1_WRITE_ADDR_0: u8 = 0,
CH6_AL1_WRITE_ADDR_1: u8 = 0,
CH6_AL1_WRITE_ADDR_2: u8 = 0,
CH6_AL1_WRITE_ADDR_3: u8 = 0,
};
/// Alias for channel 6 WRITE_ADDR register
pub const CH6_AL1_WRITE_ADDR = Register(CH6_AL1_WRITE_ADDR_val).init(base_address + 0x198);

/// CH6_AL1_READ_ADDR
const CH6_AL1_READ_ADDR_val = packed struct {
CH6_AL1_READ_ADDR_0: u8 = 0,
CH6_AL1_READ_ADDR_1: u8 = 0,
CH6_AL1_READ_ADDR_2: u8 = 0,
CH6_AL1_READ_ADDR_3: u8 = 0,
};
/// Alias for channel 6 READ_ADDR register
pub const CH6_AL1_READ_ADDR = Register(CH6_AL1_READ_ADDR_val).init(base_address + 0x194);

/// CH6_AL1_CTRL
const CH6_AL1_CTRL_val = packed struct {
CH6_AL1_CTRL_0: u8 = 0,
CH6_AL1_CTRL_1: u8 = 0,
CH6_AL1_CTRL_2: u8 = 0,
CH6_AL1_CTRL_3: u8 = 0,
};
/// Alias for channel 6 CTRL register
pub const CH6_AL1_CTRL = Register(CH6_AL1_CTRL_val).init(base_address + 0x190);

/// CH6_CTRL_TRIG
const CH6_CTRL_TRIG_val = packed struct {
/// EN [0:0]
/// DMA Channel Enable.\n
EN: u1 = 0,
/// HIGH_PRIORITY [1:1]
/// HIGH_PRIORITY gives a channel preferential treatment in issue scheduling: in each scheduling round, all high priority channels are considered first, and then only a single low priority channel, before returning to the high priority channels.\n\n
HIGH_PRIORITY: u1 = 0,
/// DATA_SIZE [2:3]
/// Set the size of each bus transfer (byte/halfword/word). READ_ADDR and WRITE_ADDR advance by this amount (1/2/4 bytes) with each transfer.
DATA_SIZE: u2 = 0,
/// INCR_READ [4:4]
/// If 1, the read address increments with each transfer. If 0, each read is directed to the same, initial address.\n\n
INCR_READ: u1 = 0,
/// INCR_WRITE [5:5]
/// If 1, the write address increments with each transfer. If 0, each write is directed to the same, initial address.\n\n
INCR_WRITE: u1 = 0,
/// RING_SIZE [6:9]
/// Size of address wrap region. If 0, don't wrap. For values n &gt; 0, only the lower n bits of the address will change. This wraps the address on a (1 &lt;&lt; n) byte boundary, facilitating access to naturally-aligned ring buffers.\n\n
RING_SIZE: u4 = 0,
/// RING_SEL [10:10]
/// Select whether RING_SIZE applies to read or write addresses.\n
RING_SEL: u1 = 0,
/// CHAIN_TO [11:14]
/// When this channel completes, it will trigger the channel indicated by CHAIN_TO. Disable by setting CHAIN_TO = _(this channel)_.\n
CHAIN_TO: u4 = 6,
/// TREQ_SEL [15:20]
/// Select a Transfer Request signal.\n
TREQ_SEL: u6 = 0,
/// IRQ_QUIET [21:21]
/// In QUIET mode, the channel does not generate IRQs at the end of every transfer block. Instead, an IRQ is raised when NULL is written to a trigger register, indicating the end of a control block chain.\n\n
IRQ_QUIET: u1 = 0,
/// BSWAP [22:22]
/// Apply byte-swap transformation to DMA data.\n
BSWAP: u1 = 0,
/// SNIFF_EN [23:23]
/// If 1, this channel's data transfers are visible to the sniff hardware, and each transfer will advance the state of the checksum. This only applies if the sniff hardware is enabled, and has this channel selected.\n\n
SNIFF_EN: u1 = 0,
/// BUSY [24:24]
/// This flag goes high when the channel starts a new transfer sequence, and low when the last transfer of that sequence completes. Clearing EN while BUSY is high pauses the channel, and BUSY will stay high while paused.\n\n
BUSY: u1 = 0,
/// unused [25:28]
_unused25: u4 = 0,
/// WRITE_ERROR [29:29]
/// If 1, the channel received a write bus error. Write one to clear.\n
WRITE_ERROR: u1 = 0,
/// READ_ERROR [30:30]
/// If 1, the channel received a read bus error. Write one to clear.\n
READ_ERROR: u1 = 0,
/// AHB_ERROR [31:31]
/// Logical OR of the READ_ERROR and WRITE_ERROR flags. The channel halts when it encounters any bus error, and always raises its channel IRQ flag.
AHB_ERROR: u1 = 0,
};
/// DMA Channel 6 Control and Status
pub const CH6_CTRL_TRIG = Register(CH6_CTRL_TRIG_val).init(base_address + 0x18c);

/// CH6_TRANS_COUNT
const CH6_TRANS_COUNT_val = packed struct {
CH6_TRANS_COUNT_0: u8 = 0,
CH6_TRANS_COUNT_1: u8 = 0,
CH6_TRANS_COUNT_2: u8 = 0,
CH6_TRANS_COUNT_3: u8 = 0,
};
/// DMA Channel 6 Transfer Count\n
pub const CH6_TRANS_COUNT = Register(CH6_TRANS_COUNT_val).init(base_address + 0x188);

/// CH6_WRITE_ADDR
const CH6_WRITE_ADDR_val = packed struct {
CH6_WRITE_ADDR_0: u8 = 0,
CH6_WRITE_ADDR_1: u8 = 0,
CH6_WRITE_ADDR_2: u8 = 0,
CH6_WRITE_ADDR_3: u8 = 0,
};
/// DMA Channel 6 Write Address pointer\n
pub const CH6_WRITE_ADDR = Register(CH6_WRITE_ADDR_val).init(base_address + 0x184);

/// CH6_READ_ADDR
const CH6_READ_ADDR_val = packed struct {
CH6_READ_ADDR_0: u8 = 0,
CH6_READ_ADDR_1: u8 = 0,
CH6_READ_ADDR_2: u8 = 0,
CH6_READ_ADDR_3: u8 = 0,
};
/// DMA Channel 6 Read Address pointer\n
pub const CH6_READ_ADDR = Register(CH6_READ_ADDR_val).init(base_address + 0x180);

/// CH5_AL3_READ_ADDR_TRIG
const CH5_AL3_READ_ADDR_TRIG_val = packed struct {
CH5_AL3_READ_ADDR_TRIG_0: u8 = 0,
CH5_AL3_READ_ADDR_TRIG_1: u8 = 0,
CH5_AL3_READ_ADDR_TRIG_2: u8 = 0,
CH5_AL3_READ_ADDR_TRIG_3: u8 = 0,
};
/// Alias for channel 5 READ_ADDR register\n
pub const CH5_AL3_READ_ADDR_TRIG = Register(CH5_AL3_READ_ADDR_TRIG_val).init(base_address + 0x17c);

/// CH5_AL3_TRANS_COUNT
const CH5_AL3_TRANS_COUNT_val = packed struct {
CH5_AL3_TRANS_COUNT_0: u8 = 0,
CH5_AL3_TRANS_COUNT_1: u8 = 0,
CH5_AL3_TRANS_COUNT_2: u8 = 0,
CH5_AL3_TRANS_COUNT_3: u8 = 0,
};
/// Alias for channel 5 TRANS_COUNT register
pub const CH5_AL3_TRANS_COUNT = Register(CH5_AL3_TRANS_COUNT_val).init(base_address + 0x178);

/// CH5_AL3_WRITE_ADDR
const CH5_AL3_WRITE_ADDR_val = packed struct {
CH5_AL3_WRITE_ADDR_0: u8 = 0,
CH5_AL3_WRITE_ADDR_1: u8 = 0,
CH5_AL3_WRITE_ADDR_2: u8 = 0,
CH5_AL3_WRITE_ADDR_3: u8 = 0,
};
/// Alias for channel 5 WRITE_ADDR register
pub const CH5_AL3_WRITE_ADDR = Register(CH5_AL3_WRITE_ADDR_val).init(base_address + 0x174);

/// CH5_AL3_CTRL
const CH5_AL3_CTRL_val = packed struct {
CH5_AL3_CTRL_0: u8 = 0,
CH5_AL3_CTRL_1: u8 = 0,
CH5_AL3_CTRL_2: u8 = 0,
CH5_AL3_CTRL_3: u8 = 0,
};
/// Alias for channel 5 CTRL register
pub const CH5_AL3_CTRL = Register(CH5_AL3_CTRL_val).init(base_address + 0x170);

/// CH5_AL2_WRITE_ADDR_TRIG
const CH5_AL2_WRITE_ADDR_TRIG_val = packed struct {
CH5_AL2_WRITE_ADDR_TRIG_0: u8 = 0,
CH5_AL2_WRITE_ADDR_TRIG_1: u8 = 0,
CH5_AL2_WRITE_ADDR_TRIG_2: u8 = 0,
CH5_AL2_WRITE_ADDR_TRIG_3: u8 = 0,
};
/// Alias for channel 5 WRITE_ADDR register\n
pub const CH5_AL2_WRITE_ADDR_TRIG = Register(CH5_AL2_WRITE_ADDR_TRIG_val).init(base_address + 0x16c);

/// CH5_AL2_READ_ADDR
const CH5_AL2_READ_ADDR_val = packed struct {
CH5_AL2_READ_ADDR_0: u8 = 0,
CH5_AL2_READ_ADDR_1: u8 = 0,
CH5_AL2_READ_ADDR_2: u8 = 0,
CH5_AL2_READ_ADDR_3: u8 = 0,
};
/// Alias for channel 5 READ_ADDR register
pub const CH5_AL2_READ_ADDR = Register(CH5_AL2_READ_ADDR_val).init(base_address + 0x168);

/// CH5_AL2_TRANS_COUNT
const CH5_AL2_TRANS_COUNT_val = packed struct {
CH5_AL2_TRANS_COUNT_0: u8 = 0,
CH5_AL2_TRANS_COUNT_1: u8 = 0,
CH5_AL2_TRANS_COUNT_2: u8 = 0,
CH5_AL2_TRANS_COUNT_3: u8 = 0,
};
/// Alias for channel 5 TRANS_COUNT register
pub const CH5_AL2_TRANS_COUNT = Register(CH5_AL2_TRANS_COUNT_val).init(base_address + 0x164);

/// CH5_AL2_CTRL
const CH5_AL2_CTRL_val = packed struct {
CH5_AL2_CTRL_0: u8 = 0,
CH5_AL2_CTRL_1: u8 = 0,
CH5_AL2_CTRL_2: u8 = 0,
CH5_AL2_CTRL_3: u8 = 0,
};
/// Alias for channel 5 CTRL register
pub const CH5_AL2_CTRL = Register(CH5_AL2_CTRL_val).init(base_address + 0x160);

/// CH5_AL1_TRANS_COUNT_TRIG
const CH5_AL1_TRANS_COUNT_TRIG_val = packed struct {
CH5_AL1_TRANS_COUNT_TRIG_0: u8 = 0,
CH5_AL1_TRANS_COUNT_TRIG_1: u8 = 0,
CH5_AL1_TRANS_COUNT_TRIG_2: u8 = 0,
CH5_AL1_TRANS_COUNT_TRIG_3: u8 = 0,
};
/// Alias for channel 5 TRANS_COUNT register\n
pub const CH5_AL1_TRANS_COUNT_TRIG = Register(CH5_AL1_TRANS_COUNT_TRIG_val).init(base_address + 0x15c);

/// CH5_AL1_WRITE_ADDR
const CH5_AL1_WRITE_ADDR_val = packed struct {
CH5_AL1_WRITE_ADDR_0: u8 = 0,
CH5_AL1_WRITE_ADDR_1: u8 = 0,
CH5_AL1_WRITE_ADDR_2: u8 = 0,
CH5_AL1_WRITE_ADDR_3: u8 = 0,
};
/// Alias for channel 5 WRITE_ADDR register
pub const CH5_AL1_WRITE_ADDR = Register(CH5_AL1_WRITE_ADDR_val).init(base_address + 0x158);

/// CH5_AL1_READ_ADDR
const CH5_AL1_READ_ADDR_val = packed struct {
CH5_AL1_READ_ADDR_0: u8 = 0,
CH5_AL1_READ_ADDR_1: u8 = 0,
CH5_AL1_READ_ADDR_2: u8 = 0,
CH5_AL1_READ_ADDR_3: u8 = 0,
};
/// Alias for channel 5 READ_ADDR register
pub const CH5_AL1_READ_ADDR = Register(CH5_AL1_READ_ADDR_val).init(base_address + 0x154);

/// CH5_AL1_CTRL
const CH5_AL1_CTRL_val = packed struct {
CH5_AL1_CTRL_0: u8 = 0,
CH5_AL1_CTRL_1: u8 = 0,
CH5_AL1_CTRL_2: u8 = 0,
CH5_AL1_CTRL_3: u8 = 0,
};
/// Alias for channel 5 CTRL register
pub const CH5_AL1_CTRL = Register(CH5_AL1_CTRL_val).init(base_address + 0x150);

/// CH5_CTRL_TRIG
const CH5_CTRL_TRIG_val = packed struct {
/// EN [0:0]
/// DMA Channel Enable.\n
EN: u1 = 0,
/// HIGH_PRIORITY [1:1]
/// HIGH_PRIORITY gives a channel preferential treatment in issue scheduling: in each scheduling round, all high priority channels are considered first, and then only a single low priority channel, before returning to the high priority channels.\n\n
HIGH_PRIORITY: u1 = 0,
/// DATA_SIZE [2:3]
/// Set the size of each bus transfer (byte/halfword/word). READ_ADDR and WRITE_ADDR advance by this amount (1/2/4 bytes) with each transfer.
DATA_SIZE: u2 = 0,
/// INCR_READ [4:4]
/// If 1, the read address increments with each transfer. If 0, each read is directed to the same, initial address.\n\n
INCR_READ: u1 = 0,
/// INCR_WRITE [5:5]
/// If 1, the write address increments with each transfer. If 0, each write is directed to the same, initial address.\n\n
INCR_WRITE: u1 = 0,
/// RING_SIZE [6:9]
/// Size of address wrap region. If 0, don't wrap. For values n &gt; 0, only the lower n bits of the address will change. This wraps the address on a (1 &lt;&lt; n) byte boundary, facilitating access to naturally-aligned ring buffers.\n\n
RING_SIZE: u4 = 0,
/// RING_SEL [10:10]
/// Select whether RING_SIZE applies to read or write addresses.\n
RING_SEL: u1 = 0,
/// CHAIN_TO [11:14]
/// When this channel completes, it will trigger the channel indicated by CHAIN_TO. Disable by setting CHAIN_TO = _(this channel)_.\n
CHAIN_TO: u4 = 5,
/// TREQ_SEL [15:20]
/// Select a Transfer Request signal.\n
TREQ_SEL: u6 = 0,
/// IRQ_QUIET [21:21]
/// In QUIET mode, the channel does not generate IRQs at the end of every transfer block. Instead, an IRQ is raised when NULL is written to a trigger register, indicating the end of a control block chain.\n\n
IRQ_QUIET: u1 = 0,
/// BSWAP [22:22]
/// Apply byte-swap transformation to DMA data.\n
BSWAP: u1 = 0,
/// SNIFF_EN [23:23]
/// If 1, this channel's data transfers are visible to the sniff hardware, and each transfer will advance the state of the checksum. This only applies if the sniff hardware is enabled, and has this channel selected.\n\n
SNIFF_EN: u1 = 0,
/// BUSY [24:24]
/// This flag goes high when the channel starts a new transfer sequence, and low when the last transfer of that sequence completes. Clearing EN while BUSY is high pauses the channel, and BUSY will stay high while paused.\n\n
BUSY: u1 = 0,
/// unused [25:28]
_unused25: u4 = 0,
/// WRITE_ERROR [29:29]
/// If 1, the channel received a write bus error. Write one to clear.\n
WRITE_ERROR: u1 = 0,
/// READ_ERROR [30:30]
/// If 1, the channel received a read bus error. Write one to clear.\n
READ_ERROR: u1 = 0,
/// AHB_ERROR [31:31]
/// Logical OR of the READ_ERROR and WRITE_ERROR flags. The channel halts when it encounters any bus error, and always raises its channel IRQ flag.
AHB_ERROR: u1 = 0,
};
/// DMA Channel 5 Control and Status
pub const CH5_CTRL_TRIG = Register(CH5_CTRL_TRIG_val).init(base_address + 0x14c);

/// CH5_TRANS_COUNT
const CH5_TRANS_COUNT_val = packed struct {
CH5_TRANS_COUNT_0: u8 = 0,
CH5_TRANS_COUNT_1: u8 = 0,
CH5_TRANS_COUNT_2: u8 = 0,
CH5_TRANS_COUNT_3: u8 = 0,
};
/// DMA Channel 5 Transfer Count\n
pub const CH5_TRANS_COUNT = Register(CH5_TRANS_COUNT_val).init(base_address + 0x148);

/// CH5_WRITE_ADDR
const CH5_WRITE_ADDR_val = packed struct {
CH5_WRITE_ADDR_0: u8 = 0,
CH5_WRITE_ADDR_1: u8 = 0,
CH5_WRITE_ADDR_2: u8 = 0,
CH5_WRITE_ADDR_3: u8 = 0,
};
/// DMA Channel 5 Write Address pointer\n
pub const CH5_WRITE_ADDR = Register(CH5_WRITE_ADDR_val).init(base_address + 0x144);

/// CH5_READ_ADDR
const CH5_READ_ADDR_val = packed struct {
CH5_READ_ADDR_0: u8 = 0,
CH5_READ_ADDR_1: u8 = 0,
CH5_READ_ADDR_2: u8 = 0,
CH5_READ_ADDR_3: u8 = 0,
};
/// DMA Channel 5 Read Address pointer\n
pub const CH5_READ_ADDR = Register(CH5_READ_ADDR_val).init(base_address + 0x140);

/// CH4_AL3_READ_ADDR_TRIG
const CH4_AL3_READ_ADDR_TRIG_val = packed struct {
CH4_AL3_READ_ADDR_TRIG_0: u8 = 0,
CH4_AL3_READ_ADDR_TRIG_1: u8 = 0,
CH4_AL3_READ_ADDR_TRIG_2: u8 = 0,
CH4_AL3_READ_ADDR_TRIG_3: u8 = 0,
};
/// Alias for channel 4 READ_ADDR register\n
pub const CH4_AL3_READ_ADDR_TRIG = Register(CH4_AL3_READ_ADDR_TRIG_val).init(base_address + 0x13c);

/// CH4_AL3_TRANS_COUNT
const CH4_AL3_TRANS_COUNT_val = packed struct {
CH4_AL3_TRANS_COUNT_0: u8 = 0,
CH4_AL3_TRANS_COUNT_1: u8 = 0,
CH4_AL3_TRANS_COUNT_2: u8 = 0,
CH4_AL3_TRANS_COUNT_3: u8 = 0,
};
/// Alias for channel 4 TRANS_COUNT register
pub const CH4_AL3_TRANS_COUNT = Register(CH4_AL3_TRANS_COUNT_val).init(base_address + 0x138);

/// CH4_AL3_WRITE_ADDR
const CH4_AL3_WRITE_ADDR_val = packed struct {
CH4_AL3_WRITE_ADDR_0: u8 = 0,
CH4_AL3_WRITE_ADDR_1: u8 = 0,
CH4_AL3_WRITE_ADDR_2: u8 = 0,
CH4_AL3_WRITE_ADDR_3: u8 = 0,
};
/// Alias for channel 4 WRITE_ADDR register
pub const CH4_AL3_WRITE_ADDR = Register(CH4_AL3_WRITE_ADDR_val).init(base_address + 0x134);

/// CH4_AL3_CTRL
const CH4_AL3_CTRL_val = packed struct {
CH4_AL3_CTRL_0: u8 = 0,
CH4_AL3_CTRL_1: u8 = 0,
CH4_AL3_CTRL_2: u8 = 0,
CH4_AL3_CTRL_3: u8 = 0,
};
/// Alias for channel 4 CTRL register
pub const CH4_AL3_CTRL = Register(CH4_AL3_CTRL_val).init(base_address + 0x130);

/// CH4_AL2_WRITE_ADDR_TRIG
const CH4_AL2_WRITE_ADDR_TRIG_val = packed struct {
CH4_AL2_WRITE_ADDR_TRIG_0: u8 = 0,
CH4_AL2_WRITE_ADDR_TRIG_1: u8 = 0,
CH4_AL2_WRITE_ADDR_TRIG_2: u8 = 0,
CH4_AL2_WRITE_ADDR_TRIG_3: u8 = 0,
};
/// Alias for channel 4 WRITE_ADDR register\n
pub const CH4_AL2_WRITE_ADDR_TRIG = Register(CH4_AL2_WRITE_ADDR_TRIG_val).init(base_address + 0x12c);

/// CH4_AL2_READ_ADDR
const CH4_AL2_READ_ADDR_val = packed struct {
CH4_AL2_READ_ADDR_0: u8 = 0,
CH4_AL2_READ_ADDR_1: u8 = 0,
CH4_AL2_READ_ADDR_2: u8 = 0,
CH4_AL2_READ_ADDR_3: u8 = 0,
};
/// Alias for channel 4 READ_ADDR register
pub const CH4_AL2_READ_ADDR = Register(CH4_AL2_READ_ADDR_val).init(base_address + 0x128);

/// CH4_AL2_TRANS_COUNT
const CH4_AL2_TRANS_COUNT_val = packed struct {
CH4_AL2_TRANS_COUNT_0: u8 = 0,
CH4_AL2_TRANS_COUNT_1: u8 = 0,
CH4_AL2_TRANS_COUNT_2: u8 = 0,
CH4_AL2_TRANS_COUNT_3: u8 = 0,
};
/// Alias for channel 4 TRANS_COUNT register
pub const CH4_AL2_TRANS_COUNT = Register(CH4_AL2_TRANS_COUNT_val).init(base_address + 0x124);

/// CH4_AL2_CTRL
const CH4_AL2_CTRL_val = packed struct {
CH4_AL2_CTRL_0: u8 = 0,
CH4_AL2_CTRL_1: u8 = 0,
CH4_AL2_CTRL_2: u8 = 0,
CH4_AL2_CTRL_3: u8 = 0,
};
/// Alias for channel 4 CTRL register
pub const CH4_AL2_CTRL = Register(CH4_AL2_CTRL_val).init(base_address + 0x120);

/// CH4_AL1_TRANS_COUNT_TRIG
const CH4_AL1_TRANS_COUNT_TRIG_val = packed struct {
CH4_AL1_TRANS_COUNT_TRIG_0: u8 = 0,
CH4_AL1_TRANS_COUNT_TRIG_1: u8 = 0,
CH4_AL1_TRANS_COUNT_TRIG_2: u8 = 0,
CH4_AL1_TRANS_COUNT_TRIG_3: u8 = 0,
};
/// Alias for channel 4 TRANS_COUNT register\n
pub const CH4_AL1_TRANS_COUNT_TRIG = Register(CH4_AL1_TRANS_COUNT_TRIG_val).init(base_address + 0x11c);

/// CH4_AL1_WRITE_ADDR
const CH4_AL1_WRITE_ADDR_val = packed struct {
CH4_AL1_WRITE_ADDR_0: u8 = 0,
CH4_AL1_WRITE_ADDR_1: u8 = 0,
CH4_AL1_WRITE_ADDR_2: u8 = 0,
CH4_AL1_WRITE_ADDR_3: u8 = 0,
};
/// Alias for channel 4 WRITE_ADDR register
pub const CH4_AL1_WRITE_ADDR = Register(CH4_AL1_WRITE_ADDR_val).init(base_address + 0x118);

/// CH4_AL1_READ_ADDR
const CH4_AL1_READ_ADDR_val = packed struct {
CH4_AL1_READ_ADDR_0: u8 = 0,
CH4_AL1_READ_ADDR_1: u8 = 0,
CH4_AL1_READ_ADDR_2: u8 = 0,
CH4_AL1_READ_ADDR_3: u8 = 0,
};
/// Alias for channel 4 READ_ADDR register
pub const CH4_AL1_READ_ADDR = Register(CH4_AL1_READ_ADDR_val).init(base_address + 0x114);

/// CH4_AL1_CTRL
const CH4_AL1_CTRL_val = packed struct {
CH4_AL1_CTRL_0: u8 = 0,
CH4_AL1_CTRL_1: u8 = 0,
CH4_AL1_CTRL_2: u8 = 0,
CH4_AL1_CTRL_3: u8 = 0,
};
/// Alias for channel 4 CTRL register
pub const CH4_AL1_CTRL = Register(CH4_AL1_CTRL_val).init(base_address + 0x110);

/// CH4_CTRL_TRIG
const CH4_CTRL_TRIG_val = packed struct {
/// EN [0:0]
/// DMA Channel Enable.\n
EN: u1 = 0,
/// HIGH_PRIORITY [1:1]
/// HIGH_PRIORITY gives a channel preferential treatment in issue scheduling: in each scheduling round, all high priority channels are considered first, and then only a single low priority channel, before returning to the high priority channels.\n\n
HIGH_PRIORITY: u1 = 0,
/// DATA_SIZE [2:3]
/// Set the size of each bus transfer (byte/halfword/word). READ_ADDR and WRITE_ADDR advance by this amount (1/2/4 bytes) with each transfer.
DATA_SIZE: u2 = 0,
/// INCR_READ [4:4]
/// If 1, the read address increments with each transfer. If 0, each read is directed to the same, initial address.\n\n
INCR_READ: u1 = 0,
/// INCR_WRITE [5:5]
/// If 1, the write address increments with each transfer. If 0, each write is directed to the same, initial address.\n\n
INCR_WRITE: u1 = 0,
/// RING_SIZE [6:9]
/// Size of address wrap region. If 0, don't wrap. For values n &gt; 0, only the lower n bits of the address will change. This wraps the address on a (1 &lt;&lt; n) byte boundary, facilitating access to naturally-aligned ring buffers.\n\n
RING_SIZE: u4 = 0,
/// RING_SEL [10:10]
/// Select whether RING_SIZE applies to read or write addresses.\n
RING_SEL: u1 = 0,
/// CHAIN_TO [11:14]
/// When this channel completes, it will trigger the channel indicated by CHAIN_TO. Disable by setting CHAIN_TO = _(this channel)_.\n
CHAIN_TO: u4 = 4,
/// TREQ_SEL [15:20]
/// Select a Transfer Request signal.\n
TREQ_SEL: u6 = 0,
/// IRQ_QUIET [21:21]
/// In QUIET mode, the channel does not generate IRQs at the end of every transfer block. Instead, an IRQ is raised when NULL is written to a trigger register, indicating the end of a control block chain.\n\n
IRQ_QUIET: u1 = 0,
/// BSWAP [22:22]
/// Apply byte-swap transformation to DMA data.\n
BSWAP: u1 = 0,
/// SNIFF_EN [23:23]
/// If 1, this channel's data transfers are visible to the sniff hardware, and each transfer will advance the state of the checksum. This only applies if the sniff hardware is enabled, and has this channel selected.\n\n
SNIFF_EN: u1 = 0,
/// BUSY [24:24]
/// This flag goes high when the channel starts a new transfer sequence, and low when the last transfer of that sequence completes. Clearing EN while BUSY is high pauses the channel, and BUSY will stay high while paused.\n\n
BUSY: u1 = 0,
/// unused [25:28]
_unused25: u4 = 0,
/// WRITE_ERROR [29:29]
/// If 1, the channel received a write bus error. Write one to clear.\n
WRITE_ERROR: u1 = 0,
/// READ_ERROR [30:30]
/// If 1, the channel received a read bus error. Write one to clear.\n
READ_ERROR: u1 = 0,
/// AHB_ERROR [31:31]
/// Logical OR of the READ_ERROR and WRITE_ERROR flags. The channel halts when it encounters any bus error, and always raises its channel IRQ flag.
AHB_ERROR: u1 = 0,
};
/// DMA Channel 4 Control and Status
pub const CH4_CTRL_TRIG = Register(CH4_CTRL_TRIG_val).init(base_address + 0x10c);

/// CH4_TRANS_COUNT
const CH4_TRANS_COUNT_val = packed struct {
CH4_TRANS_COUNT_0: u8 = 0,
CH4_TRANS_COUNT_1: u8 = 0,
CH4_TRANS_COUNT_2: u8 = 0,
CH4_TRANS_COUNT_3: u8 = 0,
};
/// DMA Channel 4 Transfer Count\n
pub const CH4_TRANS_COUNT = Register(CH4_TRANS_COUNT_val).init(base_address + 0x108);

/// CH4_WRITE_ADDR
const CH4_WRITE_ADDR_val = packed struct {
CH4_WRITE_ADDR_0: u8 = 0,
CH4_WRITE_ADDR_1: u8 = 0,
CH4_WRITE_ADDR_2: u8 = 0,
CH4_WRITE_ADDR_3: u8 = 0,
};
/// DMA Channel 4 Write Address pointer\n
pub const CH4_WRITE_ADDR = Register(CH4_WRITE_ADDR_val).init(base_address + 0x104);

/// CH4_READ_ADDR
const CH4_READ_ADDR_val = packed struct {
CH4_READ_ADDR_0: u8 = 0,
CH4_READ_ADDR_1: u8 = 0,
CH4_READ_ADDR_2: u8 = 0,
CH4_READ_ADDR_3: u8 = 0,
};
/// DMA Channel 4 Read Address pointer\n
pub const CH4_READ_ADDR = Register(CH4_READ_ADDR_val).init(base_address + 0x100);

/// CH3_AL3_READ_ADDR_TRIG
const CH3_AL3_READ_ADDR_TRIG_val = packed struct {
CH3_AL3_READ_ADDR_TRIG_0: u8 = 0,
CH3_AL3_READ_ADDR_TRIG_1: u8 = 0,
CH3_AL3_READ_ADDR_TRIG_2: u8 = 0,
CH3_AL3_READ_ADDR_TRIG_3: u8 = 0,
};
/// Alias for channel 3 READ_ADDR register\n
pub const CH3_AL3_READ_ADDR_TRIG = Register(CH3_AL3_READ_ADDR_TRIG_val).init(base_address + 0xfc);

/// CH3_AL3_TRANS_COUNT
const CH3_AL3_TRANS_COUNT_val = packed struct {
CH3_AL3_TRANS_COUNT_0: u8 = 0,
CH3_AL3_TRANS_COUNT_1: u8 = 0,
CH3_AL3_TRANS_COUNT_2: u8 = 0,
CH3_AL3_TRANS_COUNT_3: u8 = 0,
};
/// Alias for channel 3 TRANS_COUNT register
pub const CH3_AL3_TRANS_COUNT = Register(CH3_AL3_TRANS_COUNT_val).init(base_address + 0xf8);

/// CH3_AL3_WRITE_ADDR
const CH3_AL3_WRITE_ADDR_val = packed struct {
CH3_AL3_WRITE_ADDR_0: u8 = 0,
CH3_AL3_WRITE_ADDR_1: u8 = 0,
CH3_AL3_WRITE_ADDR_2: u8 = 0,
CH3_AL3_WRITE_ADDR_3: u8 = 0,
};
/// Alias for channel 3 WRITE_ADDR register
pub const CH3_AL3_WRITE_ADDR = Register(CH3_AL3_WRITE_ADDR_val).init(base_address + 0xf4);

/// CH3_AL3_CTRL
const CH3_AL3_CTRL_val = packed struct {
CH3_AL3_CTRL_0: u8 = 0,
CH3_AL3_CTRL_1: u8 = 0,
CH3_AL3_CTRL_2: u8 = 0,
CH3_AL3_CTRL_3: u8 = 0,
};
/// Alias for channel 3 CTRL register
pub const CH3_AL3_CTRL = Register(CH3_AL3_CTRL_val).init(base_address + 0xf0);

/// CH3_AL2_WRITE_ADDR_TRIG
const CH3_AL2_WRITE_ADDR_TRIG_val = packed struct {
CH3_AL2_WRITE_ADDR_TRIG_0: u8 = 0,
CH3_AL2_WRITE_ADDR_TRIG_1: u8 = 0,
CH3_AL2_WRITE_ADDR_TRIG_2: u8 = 0,
CH3_AL2_WRITE_ADDR_TRIG_3: u8 = 0,
};
/// Alias for channel 3 WRITE_ADDR register\n
pub const CH3_AL2_WRITE_ADDR_TRIG = Register(CH3_AL2_WRITE_ADDR_TRIG_val).init(base_address + 0xec);

/// CH3_AL2_READ_ADDR
const CH3_AL2_READ_ADDR_val = packed struct {
CH3_AL2_READ_ADDR_0: u8 = 0,
CH3_AL2_READ_ADDR_1: u8 = 0,
CH3_AL2_READ_ADDR_2: u8 = 0,
CH3_AL2_READ_ADDR_3: u8 = 0,
};
/// Alias for channel 3 READ_ADDR register
pub const CH3_AL2_READ_ADDR = Register(CH3_AL2_READ_ADDR_val).init(base_address + 0xe8);

/// CH3_AL2_TRANS_COUNT
const CH3_AL2_TRANS_COUNT_val = packed struct {
CH3_AL2_TRANS_COUNT_0: u8 = 0,
CH3_AL2_TRANS_COUNT_1: u8 = 0,
CH3_AL2_TRANS_COUNT_2: u8 = 0,
CH3_AL2_TRANS_COUNT_3: u8 = 0,
};
/// Alias for channel 3 TRANS_COUNT register
pub const CH3_AL2_TRANS_COUNT = Register(CH3_AL2_TRANS_COUNT_val).init(base_address + 0xe4);

/// CH3_AL2_CTRL
const CH3_AL2_CTRL_val = packed struct {
CH3_AL2_CTRL_0: u8 = 0,
CH3_AL2_CTRL_1: u8 = 0,
CH3_AL2_CTRL_2: u8 = 0,
CH3_AL2_CTRL_3: u8 = 0,
};
/// Alias for channel 3 CTRL register
pub const CH3_AL2_CTRL = Register(CH3_AL2_CTRL_val).init(base_address + 0xe0);

/// CH3_AL1_TRANS_COUNT_TRIG
const CH3_AL1_TRANS_COUNT_TRIG_val = packed struct {
CH3_AL1_TRANS_COUNT_TRIG_0: u8 = 0,
CH3_AL1_TRANS_COUNT_TRIG_1: u8 = 0,
CH3_AL1_TRANS_COUNT_TRIG_2: u8 = 0,
CH3_AL1_TRANS_COUNT_TRIG_3: u8 = 0,
};
/// Alias for channel 3 TRANS_COUNT register\n
pub const CH3_AL1_TRANS_COUNT_TRIG = Register(CH3_AL1_TRANS_COUNT_TRIG_val).init(base_address + 0xdc);

/// CH3_AL1_WRITE_ADDR
const CH3_AL1_WRITE_ADDR_val = packed struct {
CH3_AL1_WRITE_ADDR_0: u8 = 0,
CH3_AL1_WRITE_ADDR_1: u8 = 0,
CH3_AL1_WRITE_ADDR_2: u8 = 0,
CH3_AL1_WRITE_ADDR_3: u8 = 0,
};
/// Alias for channel 3 WRITE_ADDR register
pub const CH3_AL1_WRITE_ADDR = Register(CH3_AL1_WRITE_ADDR_val).init(base_address + 0xd8);

/// CH3_AL1_READ_ADDR
const CH3_AL1_READ_ADDR_val = packed struct {
CH3_AL1_READ_ADDR_0: u8 = 0,
CH3_AL1_READ_ADDR_1: u8 = 0,
CH3_AL1_READ_ADDR_2: u8 = 0,
CH3_AL1_READ_ADDR_3: u8 = 0,
};
/// Alias for channel 3 READ_ADDR register
pub const CH3_AL1_READ_ADDR = Register(CH3_AL1_READ_ADDR_val).init(base_address + 0xd4);

/// CH3_AL1_CTRL
const CH3_AL1_CTRL_val = packed struct {
CH3_AL1_CTRL_0: u8 = 0,
CH3_AL1_CTRL_1: u8 = 0,
CH3_AL1_CTRL_2: u8 = 0,
CH3_AL1_CTRL_3: u8 = 0,
};
/// Alias for channel 3 CTRL register
pub const CH3_AL1_CTRL = Register(CH3_AL1_CTRL_val).init(base_address + 0xd0);

/// CH3_CTRL_TRIG
const CH3_CTRL_TRIG_val = packed struct {
/// EN [0:0]
/// DMA Channel Enable.\n
EN: u1 = 0,
/// HIGH_PRIORITY [1:1]
/// HIGH_PRIORITY gives a channel preferential treatment in issue scheduling: in each scheduling round, all high priority channels are considered first, and then only a single low priority channel, before returning to the high priority channels.\n\n
HIGH_PRIORITY: u1 = 0,
/// DATA_SIZE [2:3]
/// Set the size of each bus transfer (byte/halfword/word). READ_ADDR and WRITE_ADDR advance by this amount (1/2/4 bytes) with each transfer.
DATA_SIZE: u2 = 0,
/// INCR_READ [4:4]
/// If 1, the read address increments with each transfer. If 0, each read is directed to the same, initial address.\n\n
INCR_READ: u1 = 0,
/// INCR_WRITE [5:5]
/// If 1, the write address increments with each transfer. If 0, each write is directed to the same, initial address.\n\n
INCR_WRITE: u1 = 0,
/// RING_SIZE [6:9]
/// Size of address wrap region. If 0, don't wrap. For values n &gt; 0, only the lower n bits of the address will change. This wraps the address on a (1 &lt;&lt; n) byte boundary, facilitating access to naturally-aligned ring buffers.\n\n
RING_SIZE: u4 = 0,
/// RING_SEL [10:10]
/// Select whether RING_SIZE applies to read or write addresses.\n
RING_SEL: u1 = 0,
/// CHAIN_TO [11:14]
/// When this channel completes, it will trigger the channel indicated by CHAIN_TO. Disable by setting CHAIN_TO = _(this channel)_.\n
CHAIN_TO: u4 = 3,
/// TREQ_SEL [15:20]
/// Select a Transfer Request signal.\n
TREQ_SEL: u6 = 0,
/// IRQ_QUIET [21:21]
/// In QUIET mode, the channel does not generate IRQs at the end of every transfer block. Instead, an IRQ is raised when NULL is written to a trigger register, indicating the end of a control block chain.\n\n
IRQ_QUIET: u1 = 0,
/// BSWAP [22:22]
/// Apply byte-swap transformation to DMA data.\n
BSWAP: u1 = 0,
/// SNIFF_EN [23:23]
/// If 1, this channel's data transfers are visible to the sniff hardware, and each transfer will advance the state of the checksum. This only applies if the sniff hardware is enabled, and has this channel selected.\n\n
SNIFF_EN: u1 = 0,
/// BUSY [24:24]
/// This flag goes high when the channel starts a new transfer sequence, and low when the last transfer of that sequence completes. Clearing EN while BUSY is high pauses the channel, and BUSY will stay high while paused.\n\n
BUSY: u1 = 0,
/// unused [25:28]
_unused25: u4 = 0,
/// WRITE_ERROR [29:29]
/// If 1, the channel received a write bus error. Write one to clear.\n
WRITE_ERROR: u1 = 0,
/// READ_ERROR [30:30]
/// If 1, the channel received a read bus error. Write one to clear.\n
READ_ERROR: u1 = 0,
/// AHB_ERROR [31:31]
/// Logical OR of the READ_ERROR and WRITE_ERROR flags. The channel halts when it encounters any bus error, and always raises its channel IRQ flag.
AHB_ERROR: u1 = 0,
};
/// DMA Channel 3 Control and Status
pub const CH3_CTRL_TRIG = Register(CH3_CTRL_TRIG_val).init(base_address + 0xcc);

/// CH3_TRANS_COUNT
const CH3_TRANS_COUNT_val = packed struct {
CH3_TRANS_COUNT_0: u8 = 0,
CH3_TRANS_COUNT_1: u8 = 0,
CH3_TRANS_COUNT_2: u8 = 0,
CH3_TRANS_COUNT_3: u8 = 0,
};
/// DMA Channel 3 Transfer Count\n
pub const CH3_TRANS_COUNT = Register(CH3_TRANS_COUNT_val).init(base_address + 0xc8);

/// CH3_WRITE_ADDR
const CH3_WRITE_ADDR_val = packed struct {
CH3_WRITE_ADDR_0: u8 = 0,
CH3_WRITE_ADDR_1: u8 = 0,
CH3_WRITE_ADDR_2: u8 = 0,
CH3_WRITE_ADDR_3: u8 = 0,
};
/// DMA Channel 3 Write Address pointer\n
pub const CH3_WRITE_ADDR = Register(CH3_WRITE_ADDR_val).init(base_address + 0xc4);

/// CH3_READ_ADDR
const CH3_READ_ADDR_val = packed struct {
CH3_READ_ADDR_0: u8 = 0,
CH3_READ_ADDR_1: u8 = 0,
CH3_READ_ADDR_2: u8 = 0,
CH3_READ_ADDR_3: u8 = 0,
};
/// DMA Channel 3 Read Address pointer\n
pub const CH3_READ_ADDR = Register(CH3_READ_ADDR_val).init(base_address + 0xc0);

/// CH2_AL3_READ_ADDR_TRIG
const CH2_AL3_READ_ADDR_TRIG_val = packed struct {
CH2_AL3_READ_ADDR_TRIG_0: u8 = 0,
CH2_AL3_READ_ADDR_TRIG_1: u8 = 0,
CH2_AL3_READ_ADDR_TRIG_2: u8 = 0,
CH2_AL3_READ_ADDR_TRIG_3: u8 = 0,
};
/// Alias for channel 2 READ_ADDR register\n
pub const CH2_AL3_READ_ADDR_TRIG = Register(CH2_AL3_READ_ADDR_TRIG_val).init(base_address + 0xbc);

/// CH2_AL3_TRANS_COUNT
const CH2_AL3_TRANS_COUNT_val = packed struct {
CH2_AL3_TRANS_COUNT_0: u8 = 0,
CH2_AL3_TRANS_COUNT_1: u8 = 0,
CH2_AL3_TRANS_COUNT_2: u8 = 0,
CH2_AL3_TRANS_COUNT_3: u8 = 0,
};
/// Alias for channel 2 TRANS_COUNT register
pub const CH2_AL3_TRANS_COUNT = Register(CH2_AL3_TRANS_COUNT_val).init(base_address + 0xb8);

/// CH2_AL3_WRITE_ADDR
const CH2_AL3_WRITE_ADDR_val = packed struct {
CH2_AL3_WRITE_ADDR_0: u8 = 0,
CH2_AL3_WRITE_ADDR_1: u8 = 0,
CH2_AL3_WRITE_ADDR_2: u8 = 0,
CH2_AL3_WRITE_ADDR_3: u8 = 0,
};
/// Alias for channel 2 WRITE_ADDR register
pub const CH2_AL3_WRITE_ADDR = Register(CH2_AL3_WRITE_ADDR_val).init(base_address + 0xb4);

/// CH2_AL3_CTRL
const CH2_AL3_CTRL_val = packed struct {
CH2_AL3_CTRL_0: u8 = 0,
CH2_AL3_CTRL_1: u8 = 0,
CH2_AL3_CTRL_2: u8 = 0,
CH2_AL3_CTRL_3: u8 = 0,
};
/// Alias for channel 2 CTRL register
pub const CH2_AL3_CTRL = Register(CH2_AL3_CTRL_val).init(base_address + 0xb0);

/// CH2_AL2_WRITE_ADDR_TRIG
const CH2_AL2_WRITE_ADDR_TRIG_val = packed struct {
CH2_AL2_WRITE_ADDR_TRIG_0: u8 = 0,
CH2_AL2_WRITE_ADDR_TRIG_1: u8 = 0,
CH2_AL2_WRITE_ADDR_TRIG_2: u8 = 0,
CH2_AL2_WRITE_ADDR_TRIG_3: u8 = 0,
};
/// Alias for channel 2 WRITE_ADDR register\n
pub const CH2_AL2_WRITE_ADDR_TRIG = Register(CH2_AL2_WRITE_ADDR_TRIG_val).init(base_address + 0xac);

/// CH2_AL2_READ_ADDR
const CH2_AL2_READ_ADDR_val = packed struct {
CH2_AL2_READ_ADDR_0: u8 = 0,
CH2_AL2_READ_ADDR_1: u8 = 0,
CH2_AL2_READ_ADDR_2: u8 = 0,
CH2_AL2_READ_ADDR_3: u8 = 0,
};
/// Alias for channel 2 READ_ADDR register
pub const CH2_AL2_READ_ADDR = Register(CH2_AL2_READ_ADDR_val).init(base_address + 0xa8);

/// CH2_AL2_TRANS_COUNT
const CH2_AL2_TRANS_COUNT_val = packed struct {
CH2_AL2_TRANS_COUNT_0: u8 = 0,
CH2_AL2_TRANS_COUNT_1: u8 = 0,
CH2_AL2_TRANS_COUNT_2: u8 = 0,
CH2_AL2_TRANS_COUNT_3: u8 = 0,
};
/// Alias for channel 2 TRANS_COUNT register
pub const CH2_AL2_TRANS_COUNT = Register(CH2_AL2_TRANS_COUNT_val).init(base_address + 0xa4);

/// CH2_AL2_CTRL
const CH2_AL2_CTRL_val = packed struct {
CH2_AL2_CTRL_0: u8 = 0,
CH2_AL2_CTRL_1: u8 = 0,
CH2_AL2_CTRL_2: u8 = 0,
CH2_AL2_CTRL_3: u8 = 0,
};
/// Alias for channel 2 CTRL register
pub const CH2_AL2_CTRL = Register(CH2_AL2_CTRL_val).init(base_address + 0xa0);

/// CH2_AL1_TRANS_COUNT_TRIG
const CH2_AL1_TRANS_COUNT_TRIG_val = packed struct {
CH2_AL1_TRANS_COUNT_TRIG_0: u8 = 0,
CH2_AL1_TRANS_COUNT_TRIG_1: u8 = 0,
CH2_AL1_TRANS_COUNT_TRIG_2: u8 = 0,
CH2_AL1_TRANS_COUNT_TRIG_3: u8 = 0,
};
/// Alias for channel 2 TRANS_COUNT register\n
pub const CH2_AL1_TRANS_COUNT_TRIG = Register(CH2_AL1_TRANS_COUNT_TRIG_val).init(base_address + 0x9c);

/// CH2_AL1_WRITE_ADDR
const CH2_AL1_WRITE_ADDR_val = packed struct {
CH2_AL1_WRITE_ADDR_0: u8 = 0,
CH2_AL1_WRITE_ADDR_1: u8 = 0,
CH2_AL1_WRITE_ADDR_2: u8 = 0,
CH2_AL1_WRITE_ADDR_3: u8 = 0,
};
/// Alias for channel 2 WRITE_ADDR register
pub const CH2_AL1_WRITE_ADDR = Register(CH2_AL1_WRITE_ADDR_val).init(base_address + 0x98);

/// CH2_AL1_READ_ADDR
const CH2_AL1_READ_ADDR_val = packed struct {
CH2_AL1_READ_ADDR_0: u8 = 0,
CH2_AL1_READ_ADDR_1: u8 = 0,
CH2_AL1_READ_ADDR_2: u8 = 0,
CH2_AL1_READ_ADDR_3: u8 = 0,
};
/// Alias for channel 2 READ_ADDR register
pub const CH2_AL1_READ_ADDR = Register(CH2_AL1_READ_ADDR_val).init(base_address + 0x94);

/// CH2_AL1_CTRL
const CH2_AL1_CTRL_val = packed struct {
CH2_AL1_CTRL_0: u8 = 0,
CH2_AL1_CTRL_1: u8 = 0,
CH2_AL1_CTRL_2: u8 = 0,
CH2_AL1_CTRL_3: u8 = 0,
};
/// Alias for channel 2 CTRL register
pub const CH2_AL1_CTRL = Register(CH2_AL1_CTRL_val).init(base_address + 0x90);

/// CH2_CTRL_TRIG
const CH2_CTRL_TRIG_val = packed struct {
/// EN [0:0]
/// DMA Channel Enable.\n
EN: u1 = 0,
/// HIGH_PRIORITY [1:1]
/// HIGH_PRIORITY gives a channel preferential treatment in issue scheduling: in each scheduling round, all high priority channels are considered first, and then only a single low priority channel, before returning to the high priority channels.\n\n
HIGH_PRIORITY: u1 = 0,
/// DATA_SIZE [2:3]
/// Set the size of each bus transfer (byte/halfword/word). READ_ADDR and WRITE_ADDR advance by this amount (1/2/4 bytes) with each transfer.
DATA_SIZE: u2 = 0,
/// INCR_READ [4:4]
/// If 1, the read address increments with each transfer. If 0, each read is directed to the same, initial address.\n\n
INCR_READ: u1 = 0,
/// INCR_WRITE [5:5]
/// If 1, the write address increments with each transfer. If 0, each write is directed to the same, initial address.\n\n
INCR_WRITE: u1 = 0,
/// RING_SIZE [6:9]
/// Size of address wrap region. If 0, don't wrap. For values n &gt; 0, only the lower n bits of the address will change. This wraps the address on a (1 &lt;&lt; n) byte boundary, facilitating access to naturally-aligned ring buffers.\n\n
RING_SIZE: u4 = 0,
/// RING_SEL [10:10]
/// Select whether RING_SIZE applies to read or write addresses.\n
RING_SEL: u1 = 0,
/// CHAIN_TO [11:14]
/// When this channel completes, it will trigger the channel indicated by CHAIN_TO. Disable by setting CHAIN_TO = _(this channel)_.\n
CHAIN_TO: u4 = 2,
/// TREQ_SEL [15:20]
/// Select a Transfer Request signal.\n
TREQ_SEL: u6 = 0,
/// IRQ_QUIET [21:21]
/// In QUIET mode, the channel does not generate IRQs at the end of every transfer block. Instead, an IRQ is raised when NULL is written to a trigger register, indicating the end of a control block chain.\n\n
IRQ_QUIET: u1 = 0,
/// BSWAP [22:22]
/// Apply byte-swap transformation to DMA data.\n
BSWAP: u1 = 0,
/// SNIFF_EN [23:23]
/// If 1, this channel's data transfers are visible to the sniff hardware, and each transfer will advance the state of the checksum. This only applies if the sniff hardware is enabled, and has this channel selected.\n\n
SNIFF_EN: u1 = 0,
/// BUSY [24:24]
/// This flag goes high when the channel starts a new transfer sequence, and low when the last transfer of that sequence completes. Clearing EN while BUSY is high pauses the channel, and BUSY will stay high while paused.\n\n
BUSY: u1 = 0,
/// unused [25:28]
_unused25: u4 = 0,
/// WRITE_ERROR [29:29]
/// If 1, the channel received a write bus error. Write one to clear.\n
WRITE_ERROR: u1 = 0,
/// READ_ERROR [30:30]
/// If 1, the channel received a read bus error. Write one to clear.\n
READ_ERROR: u1 = 0,
/// AHB_ERROR [31:31]
/// Logical OR of the READ_ERROR and WRITE_ERROR flags. The channel halts when it encounters any bus error, and always raises its channel IRQ flag.
AHB_ERROR: u1 = 0,
};
/// DMA Channel 2 Control and Status
pub const CH2_CTRL_TRIG = Register(CH2_CTRL_TRIG_val).init(base_address + 0x8c);

/// CH2_TRANS_COUNT
const CH2_TRANS_COUNT_val = packed struct {
CH2_TRANS_COUNT_0: u8 = 0,
CH2_TRANS_COUNT_1: u8 = 0,
CH2_TRANS_COUNT_2: u8 = 0,
CH2_TRANS_COUNT_3: u8 = 0,
};
/// DMA Channel 2 Transfer Count\n
pub const CH2_TRANS_COUNT = Register(CH2_TRANS_COUNT_val).init(base_address + 0x88);

/// CH2_WRITE_ADDR
const CH2_WRITE_ADDR_val = packed struct {
CH2_WRITE_ADDR_0: u8 = 0,
CH2_WRITE_ADDR_1: u8 = 0,
CH2_WRITE_ADDR_2: u8 = 0,
CH2_WRITE_ADDR_3: u8 = 0,
};
/// DMA Channel 2 Write Address pointer\n
pub const CH2_WRITE_ADDR = Register(CH2_WRITE_ADDR_val).init(base_address + 0x84);

/// CH2_READ_ADDR
const CH2_READ_ADDR_val = packed struct {
CH2_READ_ADDR_0: u8 = 0,
CH2_READ_ADDR_1: u8 = 0,
CH2_READ_ADDR_2: u8 = 0,
CH2_READ_ADDR_3: u8 = 0,
};
/// DMA Channel 2 Read Address pointer\n
pub const CH2_READ_ADDR = Register(CH2_READ_ADDR_val).init(base_address + 0x80);

/// CH1_AL3_READ_ADDR_TRIG
const CH1_AL3_READ_ADDR_TRIG_val = packed struct {
CH1_AL3_READ_ADDR_TRIG_0: u8 = 0,
CH1_AL3_READ_ADDR_TRIG_1: u8 = 0,
CH1_AL3_READ_ADDR_TRIG_2: u8 = 0,
CH1_AL3_READ_ADDR_TRIG_3: u8 = 0,
};
/// Alias for channel 1 READ_ADDR register\n
pub const CH1_AL3_READ_ADDR_TRIG = Register(CH1_AL3_READ_ADDR_TRIG_val).init(base_address + 0x7c);

/// CH1_AL3_TRANS_COUNT
const CH1_AL3_TRANS_COUNT_val = packed struct {
CH1_AL3_TRANS_COUNT_0: u8 = 0,
CH1_AL3_TRANS_COUNT_1: u8 = 0,
CH1_AL3_TRANS_COUNT_2: u8 = 0,
CH1_AL3_TRANS_COUNT_3: u8 = 0,
};
/// Alias for channel 1 TRANS_COUNT register
pub const CH1_AL3_TRANS_COUNT = Register(CH1_AL3_TRANS_COUNT_val).init(base_address + 0x78);

/// CH1_AL3_WRITE_ADDR
const CH1_AL3_WRITE_ADDR_val = packed struct {
CH1_AL3_WRITE_ADDR_0: u8 = 0,
CH1_AL3_WRITE_ADDR_1: u8 = 0,
CH1_AL3_WRITE_ADDR_2: u8 = 0,
CH1_AL3_WRITE_ADDR_3: u8 = 0,
};
/// Alias for channel 1 WRITE_ADDR register
pub const CH1_AL3_WRITE_ADDR = Register(CH1_AL3_WRITE_ADDR_val).init(base_address + 0x74);

/// CH1_AL3_CTRL
const CH1_AL3_CTRL_val = packed struct {
CH1_AL3_CTRL_0: u8 = 0,
CH1_AL3_CTRL_1: u8 = 0,
CH1_AL3_CTRL_2: u8 = 0,
CH1_AL3_CTRL_3: u8 = 0,
};
/// Alias for channel 1 CTRL register
pub const CH1_AL3_CTRL = Register(CH1_AL3_CTRL_val).init(base_address + 0x70);

/// CH1_AL2_WRITE_ADDR_TRIG
const CH1_AL2_WRITE_ADDR_TRIG_val = packed struct {
CH1_AL2_WRITE_ADDR_TRIG_0: u8 = 0,
CH1_AL2_WRITE_ADDR_TRIG_1: u8 = 0,
CH1_AL2_WRITE_ADDR_TRIG_2: u8 = 0,
CH1_AL2_WRITE_ADDR_TRIG_3: u8 = 0,
};
/// Alias for channel 1 WRITE_ADDR register\n
pub const CH1_AL2_WRITE_ADDR_TRIG = Register(CH1_AL2_WRITE_ADDR_TRIG_val).init(base_address + 0x6c);

/// CH1_AL2_READ_ADDR
const CH1_AL2_READ_ADDR_val = packed struct {
CH1_AL2_READ_ADDR_0: u8 = 0,
CH1_AL2_READ_ADDR_1: u8 = 0,
CH1_AL2_READ_ADDR_2: u8 = 0,
CH1_AL2_READ_ADDR_3: u8 = 0,
};
/// Alias for channel 1 READ_ADDR register
pub const CH1_AL2_READ_ADDR = Register(CH1_AL2_READ_ADDR_val).init(base_address + 0x68);

/// CH1_AL2_TRANS_COUNT
const CH1_AL2_TRANS_COUNT_val = packed struct {
CH1_AL2_TRANS_COUNT_0: u8 = 0,
CH1_AL2_TRANS_COUNT_1: u8 = 0,
CH1_AL2_TRANS_COUNT_2: u8 = 0,
CH1_AL2_TRANS_COUNT_3: u8 = 0,
};
/// Alias for channel 1 TRANS_COUNT register
pub const CH1_AL2_TRANS_COUNT = Register(CH1_AL2_TRANS_COUNT_val).init(base_address + 0x64);

/// CH1_AL2_CTRL
const CH1_AL2_CTRL_val = packed struct {
CH1_AL2_CTRL_0: u8 = 0,
CH1_AL2_CTRL_1: u8 = 0,
CH1_AL2_CTRL_2: u8 = 0,
CH1_AL2_CTRL_3: u8 = 0,
};
/// Alias for channel 1 CTRL register
pub const CH1_AL2_CTRL = Register(CH1_AL2_CTRL_val).init(base_address + 0x60);

/// CH1_AL1_TRANS_COUNT_TRIG
const CH1_AL1_TRANS_COUNT_TRIG_val = packed struct {
CH1_AL1_TRANS_COUNT_TRIG_0: u8 = 0,
CH1_AL1_TRANS_COUNT_TRIG_1: u8 = 0,
CH1_AL1_TRANS_COUNT_TRIG_2: u8 = 0,
CH1_AL1_TRANS_COUNT_TRIG_3: u8 = 0,
};
/// Alias for channel 1 TRANS_COUNT register\n
pub const CH1_AL1_TRANS_COUNT_TRIG = Register(CH1_AL1_TRANS_COUNT_TRIG_val).init(base_address + 0x5c);

/// CH1_AL1_WRITE_ADDR
const CH1_AL1_WRITE_ADDR_val = packed struct {
CH1_AL1_WRITE_ADDR_0: u8 = 0,
CH1_AL1_WRITE_ADDR_1: u8 = 0,
CH1_AL1_WRITE_ADDR_2: u8 = 0,
CH1_AL1_WRITE_ADDR_3: u8 = 0,
};
/// Alias for channel 1 WRITE_ADDR register
pub const CH1_AL1_WRITE_ADDR = Register(CH1_AL1_WRITE_ADDR_val).init(base_address + 0x58);

/// CH1_AL1_READ_ADDR
const CH1_AL1_READ_ADDR_val = packed struct {
CH1_AL1_READ_ADDR_0: u8 = 0,
CH1_AL1_READ_ADDR_1: u8 = 0,
CH1_AL1_READ_ADDR_2: u8 = 0,
CH1_AL1_READ_ADDR_3: u8 = 0,
};
/// Alias for channel 1 READ_ADDR register
pub const CH1_AL1_READ_ADDR = Register(CH1_AL1_READ_ADDR_val).init(base_address + 0x54);

/// CH1_AL1_CTRL
const CH1_AL1_CTRL_val = packed struct {
CH1_AL1_CTRL_0: u8 = 0,
CH1_AL1_CTRL_1: u8 = 0,
CH1_AL1_CTRL_2: u8 = 0,
CH1_AL1_CTRL_3: u8 = 0,
};
/// Alias for channel 1 CTRL register
pub const CH1_AL1_CTRL = Register(CH1_AL1_CTRL_val).init(base_address + 0x50);

/// CH1_CTRL_TRIG
const CH1_CTRL_TRIG_val = packed struct {
/// EN [0:0]
/// DMA Channel Enable.\n
EN: u1 = 0,
/// HIGH_PRIORITY [1:1]
/// HIGH_PRIORITY gives a channel preferential treatment in issue scheduling: in each scheduling round, all high priority channels are considered first, and then only a single low priority channel, before returning to the high priority channels.\n\n
HIGH_PRIORITY: u1 = 0,
/// DATA_SIZE [2:3]
/// Set the size of each bus transfer (byte/halfword/word). READ_ADDR and WRITE_ADDR advance by this amount (1/2/4 bytes) with each transfer.
DATA_SIZE: u2 = 0,
/// INCR_READ [4:4]
/// If 1, the read address increments with each transfer. If 0, each read is directed to the same, initial address.\n\n
INCR_READ: u1 = 0,
/// INCR_WRITE [5:5]
/// If 1, the write address increments with each transfer. If 0, each write is directed to the same, initial address.\n\n
INCR_WRITE: u1 = 0,
/// RING_SIZE [6:9]
/// Size of address wrap region. If 0, don't wrap. For values n &gt; 0, only the lower n bits of the address will change. This wraps the address on a (1 &lt;&lt; n) byte boundary, facilitating access to naturally-aligned ring buffers.\n\n
RING_SIZE: u4 = 0,
/// RING_SEL [10:10]
/// Select whether RING_SIZE applies to read or write addresses.\n
RING_SEL: u1 = 0,
/// CHAIN_TO [11:14]
/// When this channel completes, it will trigger the channel indicated by CHAIN_TO. Disable by setting CHAIN_TO = _(this channel)_.\n
CHAIN_TO: u4 = 1,
/// TREQ_SEL [15:20]
/// Select a Transfer Request signal.\n
TREQ_SEL: u6 = 0,
/// IRQ_QUIET [21:21]
/// In QUIET mode, the channel does not generate IRQs at the end of every transfer block. Instead, an IRQ is raised when NULL is written to a trigger register, indicating the end of a control block chain.\n\n
IRQ_QUIET: u1 = 0,
/// BSWAP [22:22]
/// Apply byte-swap transformation to DMA data.\n
BSWAP: u1 = 0,
/// SNIFF_EN [23:23]
/// If 1, this channel's data transfers are visible to the sniff hardware, and each transfer will advance the state of the checksum. This only applies if the sniff hardware is enabled, and has this channel selected.\n\n
SNIFF_EN: u1 = 0,
/// BUSY [24:24]
/// This flag goes high when the channel starts a new transfer sequence, and low when the last transfer of that sequence completes. Clearing EN while BUSY is high pauses the channel, and BUSY will stay high while paused.\n\n
BUSY: u1 = 0,
/// unused [25:28]
_unused25: u4 = 0,
/// WRITE_ERROR [29:29]
/// If 1, the channel received a write bus error. Write one to clear.\n
WRITE_ERROR: u1 = 0,
/// READ_ERROR [30:30]
/// If 1, the channel received a read bus error. Write one to clear.\n
READ_ERROR: u1 = 0,
/// AHB_ERROR [31:31]
/// Logical OR of the READ_ERROR and WRITE_ERROR flags. The channel halts when it encounters any bus error, and always raises its channel IRQ flag.
AHB_ERROR: u1 = 0,
};
/// DMA Channel 1 Control and Status
pub const CH1_CTRL_TRIG = Register(CH1_CTRL_TRIG_val).init(base_address + 0x4c);

/// CH1_TRANS_COUNT
const CH1_TRANS_COUNT_val = packed struct {
CH1_TRANS_COUNT_0: u8 = 0,
CH1_TRANS_COUNT_1: u8 = 0,
CH1_TRANS_COUNT_2: u8 = 0,
CH1_TRANS_COUNT_3: u8 = 0,
};
/// DMA Channel 1 Transfer Count\n
pub const CH1_TRANS_COUNT = Register(CH1_TRANS_COUNT_val).init(base_address + 0x48);

/// CH1_WRITE_ADDR
const CH1_WRITE_ADDR_val = packed struct {
CH1_WRITE_ADDR_0: u8 = 0,
CH1_WRITE_ADDR_1: u8 = 0,
CH1_WRITE_ADDR_2: u8 = 0,
CH1_WRITE_ADDR_3: u8 = 0,
};
/// DMA Channel 1 Write Address pointer\n
pub const CH1_WRITE_ADDR = Register(CH1_WRITE_ADDR_val).init(base_address + 0x44);

/// CH1_READ_ADDR
const CH1_READ_ADDR_val = packed struct {
CH1_READ_ADDR_0: u8 = 0,
CH1_READ_ADDR_1: u8 = 0,
CH1_READ_ADDR_2: u8 = 0,
CH1_READ_ADDR_3: u8 = 0,
};
/// DMA Channel 1 Read Address pointer\n
pub const CH1_READ_ADDR = Register(CH1_READ_ADDR_val).init(base_address + 0x40);

/// CH0_AL3_READ_ADDR_TRIG
const CH0_AL3_READ_ADDR_TRIG_val = packed struct {
CH0_AL3_READ_ADDR_TRIG_0: u8 = 0,
CH0_AL3_READ_ADDR_TRIG_1: u8 = 0,
CH0_AL3_READ_ADDR_TRIG_2: u8 = 0,
CH0_AL3_READ_ADDR_TRIG_3: u8 = 0,
};
/// Alias for channel 0 READ_ADDR register\n
pub const CH0_AL3_READ_ADDR_TRIG = Register(CH0_AL3_READ_ADDR_TRIG_val).init(base_address + 0x3c);

/// CH0_AL3_TRANS_COUNT
const CH0_AL3_TRANS_COUNT_val = packed struct {
CH0_AL3_TRANS_COUNT_0: u8 = 0,
CH0_AL3_TRANS_COUNT_1: u8 = 0,
CH0_AL3_TRANS_COUNT_2: u8 = 0,
CH0_AL3_TRANS_COUNT_3: u8 = 0,
};
/// Alias for channel 0 TRANS_COUNT register
pub const CH0_AL3_TRANS_COUNT = Register(CH0_AL3_TRANS_COUNT_val).init(base_address + 0x38);

/// CH0_AL3_WRITE_ADDR
const CH0_AL3_WRITE_ADDR_val = packed struct {
CH0_AL3_WRITE_ADDR_0: u8 = 0,
CH0_AL3_WRITE_ADDR_1: u8 = 0,
CH0_AL3_WRITE_ADDR_2: u8 = 0,
CH0_AL3_WRITE_ADDR_3: u8 = 0,
};
/// Alias for channel 0 WRITE_ADDR register
pub const CH0_AL3_WRITE_ADDR = Register(CH0_AL3_WRITE_ADDR_val).init(base_address + 0x34);

/// CH0_AL3_CTRL
const CH0_AL3_CTRL_val = packed struct {
CH0_AL3_CTRL_0: u8 = 0,
CH0_AL3_CTRL_1: u8 = 0,
CH0_AL3_CTRL_2: u8 = 0,
CH0_AL3_CTRL_3: u8 = 0,
};
/// Alias for channel 0 CTRL register
pub const CH0_AL3_CTRL = Register(CH0_AL3_CTRL_val).init(base_address + 0x30);

/// CH0_AL2_WRITE_ADDR_TRIG
const CH0_AL2_WRITE_ADDR_TRIG_val = packed struct {
CH0_AL2_WRITE_ADDR_TRIG_0: u8 = 0,
CH0_AL2_WRITE_ADDR_TRIG_1: u8 = 0,
CH0_AL2_WRITE_ADDR_TRIG_2: u8 = 0,
CH0_AL2_WRITE_ADDR_TRIG_3: u8 = 0,
};
/// Alias for channel 0 WRITE_ADDR register\n
pub const CH0_AL2_WRITE_ADDR_TRIG = Register(CH0_AL2_WRITE_ADDR_TRIG_val).init(base_address + 0x2c);

/// CH0_AL2_READ_ADDR
const CH0_AL2_READ_ADDR_val = packed struct {
CH0_AL2_READ_ADDR_0: u8 = 0,
CH0_AL2_READ_ADDR_1: u8 = 0,
CH0_AL2_READ_ADDR_2: u8 = 0,
CH0_AL2_READ_ADDR_3: u8 = 0,
};
/// Alias for channel 0 READ_ADDR register
pub const CH0_AL2_READ_ADDR = Register(CH0_AL2_READ_ADDR_val).init(base_address + 0x28);

/// CH0_AL2_TRANS_COUNT
const CH0_AL2_TRANS_COUNT_val = packed struct {
CH0_AL2_TRANS_COUNT_0: u8 = 0,
CH0_AL2_TRANS_COUNT_1: u8 = 0,
CH0_AL2_TRANS_COUNT_2: u8 = 0,
CH0_AL2_TRANS_COUNT_3: u8 = 0,
};
/// Alias for channel 0 TRANS_COUNT register
pub const CH0_AL2_TRANS_COUNT = Register(CH0_AL2_TRANS_COUNT_val).init(base_address + 0x24);

/// CH0_AL2_CTRL
const CH0_AL2_CTRL_val = packed struct {
CH0_AL2_CTRL_0: u8 = 0,
CH0_AL2_CTRL_1: u8 = 0,
CH0_AL2_CTRL_2: u8 = 0,
CH0_AL2_CTRL_3: u8 = 0,
};
/// Alias for channel 0 CTRL register
pub const CH0_AL2_CTRL = Register(CH0_AL2_CTRL_val).init(base_address + 0x20);

/// CH0_AL1_TRANS_COUNT_TRIG
const CH0_AL1_TRANS_COUNT_TRIG_val = packed struct {
CH0_AL1_TRANS_COUNT_TRIG_0: u8 = 0,
CH0_AL1_TRANS_COUNT_TRIG_1: u8 = 0,
CH0_AL1_TRANS_COUNT_TRIG_2: u8 = 0,
CH0_AL1_TRANS_COUNT_TRIG_3: u8 = 0,
};
/// Alias for channel 0 TRANS_COUNT register\n
pub const CH0_AL1_TRANS_COUNT_TRIG = Register(CH0_AL1_TRANS_COUNT_TRIG_val).init(base_address + 0x1c);

/// CH0_AL1_WRITE_ADDR
const CH0_AL1_WRITE_ADDR_val = packed struct {
CH0_AL1_WRITE_ADDR_0: u8 = 0,
CH0_AL1_WRITE_ADDR_1: u8 = 0,
CH0_AL1_WRITE_ADDR_2: u8 = 0,
CH0_AL1_WRITE_ADDR_3: u8 = 0,
};
/// Alias for channel 0 WRITE_ADDR register
pub const CH0_AL1_WRITE_ADDR = Register(CH0_AL1_WRITE_ADDR_val).init(base_address + 0x18);

/// CH0_AL1_READ_ADDR
const CH0_AL1_READ_ADDR_val = packed struct {
CH0_AL1_READ_ADDR_0: u8 = 0,
CH0_AL1_READ_ADDR_1: u8 = 0,
CH0_AL1_READ_ADDR_2: u8 = 0,
CH0_AL1_READ_ADDR_3: u8 = 0,
};
/// Alias for channel 0 READ_ADDR register
pub const CH0_AL1_READ_ADDR = Register(CH0_AL1_READ_ADDR_val).init(base_address + 0x14);

/// CH0_AL1_CTRL
const CH0_AL1_CTRL_val = packed struct {
CH0_AL1_CTRL_0: u8 = 0,
CH0_AL1_CTRL_1: u8 = 0,
CH0_AL1_CTRL_2: u8 = 0,
CH0_AL1_CTRL_3: u8 = 0,
};
/// Alias for channel 0 CTRL register
pub const CH0_AL1_CTRL = Register(CH0_AL1_CTRL_val).init(base_address + 0x10);

/// CH0_CTRL_TRIG
const CH0_CTRL_TRIG_val = packed struct {
/// EN [0:0]
/// DMA Channel Enable.\n
EN: u1 = 0,
/// HIGH_PRIORITY [1:1]
/// HIGH_PRIORITY gives a channel preferential treatment in issue scheduling: in each scheduling round, all high priority channels are considered first, and then only a single low priority channel, before returning to the high priority channels.\n\n
HIGH_PRIORITY: u1 = 0,
/// DATA_SIZE [2:3]
/// Set the size of each bus transfer (byte/halfword/word). READ_ADDR and WRITE_ADDR advance by this amount (1/2/4 bytes) with each transfer.
DATA_SIZE: u2 = 0,
/// INCR_READ [4:4]
/// If 1, the read address increments with each transfer. If 0, each read is directed to the same, initial address.\n\n
INCR_READ: u1 = 0,
/// INCR_WRITE [5:5]
/// If 1, the write address increments with each transfer. If 0, each write is directed to the same, initial address.\n\n
INCR_WRITE: u1 = 0,
/// RING_SIZE [6:9]
/// Size of address wrap region. If 0, don't wrap. For values n &gt; 0, only the lower n bits of the address will change. This wraps the address on a (1 &lt;&lt; n) byte boundary, facilitating access to naturally-aligned ring buffers.\n\n
RING_SIZE: u4 = 0,
/// RING_SEL [10:10]
/// Select whether RING_SIZE applies to read or write addresses.\n
RING_SEL: u1 = 0,
/// CHAIN_TO [11:14]
/// When this channel completes, it will trigger the channel indicated by CHAIN_TO. Disable by setting CHAIN_TO = _(this channel)_.\n
CHAIN_TO: u4 = 0,
/// TREQ_SEL [15:20]
/// Select a Transfer Request signal.\n
TREQ_SEL: u6 = 0,
/// IRQ_QUIET [21:21]
/// In QUIET mode, the channel does not generate IRQs at the end of every transfer block. Instead, an IRQ is raised when NULL is written to a trigger register, indicating the end of a control block chain.\n\n
IRQ_QUIET: u1 = 0,
/// BSWAP [22:22]
/// Apply byte-swap transformation to DMA data.\n
BSWAP: u1 = 0,
/// SNIFF_EN [23:23]
/// If 1, this channel's data transfers are visible to the sniff hardware, and each transfer will advance the state of the checksum. This only applies if the sniff hardware is enabled, and has this channel selected.\n\n
SNIFF_EN: u1 = 0,
/// BUSY [24:24]
/// This flag goes high when the channel starts a new transfer sequence, and low when the last transfer of that sequence completes. Clearing EN while BUSY is high pauses the channel, and BUSY will stay high while paused.\n\n
BUSY: u1 = 0,
/// unused [25:28]
_unused25: u4 = 0,
/// WRITE_ERROR [29:29]
/// If 1, the channel received a write bus error. Write one to clear.\n
WRITE_ERROR: u1 = 0,
/// READ_ERROR [30:30]
/// If 1, the channel received a read bus error. Write one to clear.\n
READ_ERROR: u1 = 0,
/// AHB_ERROR [31:31]
/// Logical OR of the READ_ERROR and WRITE_ERROR flags. The channel halts when it encounters any bus error, and always raises its channel IRQ flag.
AHB_ERROR: u1 = 0,
};
/// DMA Channel 0 Control and Status
pub const CH0_CTRL_TRIG = Register(CH0_CTRL_TRIG_val).init(base_address + 0xc);

/// CH0_TRANS_COUNT
const CH0_TRANS_COUNT_val = packed struct {
CH0_TRANS_COUNT_0: u8 = 0,
CH0_TRANS_COUNT_1: u8 = 0,
CH0_TRANS_COUNT_2: u8 = 0,
CH0_TRANS_COUNT_3: u8 = 0,
};
/// DMA Channel 0 Transfer Count\n
pub const CH0_TRANS_COUNT = Register(CH0_TRANS_COUNT_val).init(base_address + 0x8);

/// CH0_WRITE_ADDR
const CH0_WRITE_ADDR_val = packed struct {
CH0_WRITE_ADDR_0: u8 = 0,
CH0_WRITE_ADDR_1: u8 = 0,
CH0_WRITE_ADDR_2: u8 = 0,
CH0_WRITE_ADDR_3: u8 = 0,
};
/// DMA Channel 0 Write Address pointer\n
pub const CH0_WRITE_ADDR = Register(CH0_WRITE_ADDR_val).init(base_address + 0x4);

/// CH0_READ_ADDR
const CH0_READ_ADDR_val = packed struct {
CH0_READ_ADDR_0: u8 = 0,
CH0_READ_ADDR_1: u8 = 0,
CH0_READ_ADDR_2: u8 = 0,
CH0_READ_ADDR_3: u8 = 0,
};
/// DMA Channel 0 Read Address pointer\n
pub const CH0_READ_ADDR = Register(CH0_READ_ADDR_val).init(base_address + 0x0);
};

/// DPRAM layout for USB device.
pub const USBCTRL_DPRAM = struct {

const base_address = 0x50100000;
/// EP15_OUT_BUFFER_CONTROL
const EP15_OUT_BUFFER_CONTROL_val = packed struct {
/// LENGTH_0 [0:9]
/// The length of the data in buffer 1.
LENGTH_0: u10 = 0,
/// AVAILABLE_0 [10:10]
/// Buffer 0 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_0: u1 = 0,
/// STALL [11:11]
/// Reply with a stall (valid for both buffers).
STALL: u1 = 0,
/// RESET [12:12]
/// Reset the buffer selector to buffer 0.
RESET: u1 = 0,
/// PID_0 [13:13]
/// The data pid of buffer 0.
PID_0: u1 = 0,
/// LAST_0 [14:14]
/// Buffer 0 is the last buffer of the transfer.
LAST_0: u1 = 0,
/// FULL_0 [15:15]
/// Buffer 0 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_0: u1 = 0,
/// LENGTH_1 [16:25]
/// The length of the data in buffer 1.
LENGTH_1: u10 = 0,
/// AVAILABLE_1 [26:26]
/// Buffer 1 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_1: u1 = 0,
/// DOUBLE_BUFFER_ISO_OFFSET [27:28]
/// The number of bytes buffer 1 is offset from buffer 0 in Isochronous mode. Only valid in double buffered mode for an Isochronous endpoint.\n
DOUBLE_BUFFER_ISO_OFFSET: u2 = 0,
/// PID_1 [29:29]
/// The data pid of buffer 1.
PID_1: u1 = 0,
/// LAST_1 [30:30]
/// Buffer 1 is the last buffer of the transfer.
LAST_1: u1 = 0,
/// FULL_1 [31:31]
/// Buffer 1 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_1: u1 = 0,
};
/// Buffer control for both buffers of an endpoint. Fields ending in a _1 are for buffer 1.\n
pub const EP15_OUT_BUFFER_CONTROL = Register(EP15_OUT_BUFFER_CONTROL_val).init(base_address + 0xfc);

/// EP15_IN_BUFFER_CONTROL
const EP15_IN_BUFFER_CONTROL_val = packed struct {
/// LENGTH_0 [0:9]
/// The length of the data in buffer 1.
LENGTH_0: u10 = 0,
/// AVAILABLE_0 [10:10]
/// Buffer 0 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_0: u1 = 0,
/// STALL [11:11]
/// Reply with a stall (valid for both buffers).
STALL: u1 = 0,
/// RESET [12:12]
/// Reset the buffer selector to buffer 0.
RESET: u1 = 0,
/// PID_0 [13:13]
/// The data pid of buffer 0.
PID_0: u1 = 0,
/// LAST_0 [14:14]
/// Buffer 0 is the last buffer of the transfer.
LAST_0: u1 = 0,
/// FULL_0 [15:15]
/// Buffer 0 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_0: u1 = 0,
/// LENGTH_1 [16:25]
/// The length of the data in buffer 1.
LENGTH_1: u10 = 0,
/// AVAILABLE_1 [26:26]
/// Buffer 1 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_1: u1 = 0,
/// DOUBLE_BUFFER_ISO_OFFSET [27:28]
/// The number of bytes buffer 1 is offset from buffer 0 in Isochronous mode. Only valid in double buffered mode for an Isochronous endpoint.\n
DOUBLE_BUFFER_ISO_OFFSET: u2 = 0,
/// PID_1 [29:29]
/// The data pid of buffer 1.
PID_1: u1 = 0,
/// LAST_1 [30:30]
/// Buffer 1 is the last buffer of the transfer.
LAST_1: u1 = 0,
/// FULL_1 [31:31]
/// Buffer 1 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_1: u1 = 0,
};
/// Buffer control for both buffers of an endpoint. Fields ending in a _1 are for buffer 1.\n
pub const EP15_IN_BUFFER_CONTROL = Register(EP15_IN_BUFFER_CONTROL_val).init(base_address + 0xf8);

/// EP14_OUT_BUFFER_CONTROL
const EP14_OUT_BUFFER_CONTROL_val = packed struct {
/// LENGTH_0 [0:9]
/// The length of the data in buffer 1.
LENGTH_0: u10 = 0,
/// AVAILABLE_0 [10:10]
/// Buffer 0 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_0: u1 = 0,
/// STALL [11:11]
/// Reply with a stall (valid for both buffers).
STALL: u1 = 0,
/// RESET [12:12]
/// Reset the buffer selector to buffer 0.
RESET: u1 = 0,
/// PID_0 [13:13]
/// The data pid of buffer 0.
PID_0: u1 = 0,
/// LAST_0 [14:14]
/// Buffer 0 is the last buffer of the transfer.
LAST_0: u1 = 0,
/// FULL_0 [15:15]
/// Buffer 0 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_0: u1 = 0,
/// LENGTH_1 [16:25]
/// The length of the data in buffer 1.
LENGTH_1: u10 = 0,
/// AVAILABLE_1 [26:26]
/// Buffer 1 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_1: u1 = 0,
/// DOUBLE_BUFFER_ISO_OFFSET [27:28]
/// The number of bytes buffer 1 is offset from buffer 0 in Isochronous mode. Only valid in double buffered mode for an Isochronous endpoint.\n
DOUBLE_BUFFER_ISO_OFFSET: u2 = 0,
/// PID_1 [29:29]
/// The data pid of buffer 1.
PID_1: u1 = 0,
/// LAST_1 [30:30]
/// Buffer 1 is the last buffer of the transfer.
LAST_1: u1 = 0,
/// FULL_1 [31:31]
/// Buffer 1 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_1: u1 = 0,
};
/// Buffer control for both buffers of an endpoint. Fields ending in a _1 are for buffer 1.\n
pub const EP14_OUT_BUFFER_CONTROL = Register(EP14_OUT_BUFFER_CONTROL_val).init(base_address + 0xf4);

/// EP14_IN_BUFFER_CONTROL
const EP14_IN_BUFFER_CONTROL_val = packed struct {
/// LENGTH_0 [0:9]
/// The length of the data in buffer 1.
LENGTH_0: u10 = 0,
/// AVAILABLE_0 [10:10]
/// Buffer 0 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_0: u1 = 0,
/// STALL [11:11]
/// Reply with a stall (valid for both buffers).
STALL: u1 = 0,
/// RESET [12:12]
/// Reset the buffer selector to buffer 0.
RESET: u1 = 0,
/// PID_0 [13:13]
/// The data pid of buffer 0.
PID_0: u1 = 0,
/// LAST_0 [14:14]
/// Buffer 0 is the last buffer of the transfer.
LAST_0: u1 = 0,
/// FULL_0 [15:15]
/// Buffer 0 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_0: u1 = 0,
/// LENGTH_1 [16:25]
/// The length of the data in buffer 1.
LENGTH_1: u10 = 0,
/// AVAILABLE_1 [26:26]
/// Buffer 1 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_1: u1 = 0,
/// DOUBLE_BUFFER_ISO_OFFSET [27:28]
/// The number of bytes buffer 1 is offset from buffer 0 in Isochronous mode. Only valid in double buffered mode for an Isochronous endpoint.\n
DOUBLE_BUFFER_ISO_OFFSET: u2 = 0,
/// PID_1 [29:29]
/// The data pid of buffer 1.
PID_1: u1 = 0,
/// LAST_1 [30:30]
/// Buffer 1 is the last buffer of the transfer.
LAST_1: u1 = 0,
/// FULL_1 [31:31]
/// Buffer 1 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_1: u1 = 0,
};
/// Buffer control for both buffers of an endpoint. Fields ending in a _1 are for buffer 1.\n
pub const EP14_IN_BUFFER_CONTROL = Register(EP14_IN_BUFFER_CONTROL_val).init(base_address + 0xf0);

/// EP13_OUT_BUFFER_CONTROL
const EP13_OUT_BUFFER_CONTROL_val = packed struct {
/// LENGTH_0 [0:9]
/// The length of the data in buffer 1.
LENGTH_0: u10 = 0,
/// AVAILABLE_0 [10:10]
/// Buffer 0 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_0: u1 = 0,
/// STALL [11:11]
/// Reply with a stall (valid for both buffers).
STALL: u1 = 0,
/// RESET [12:12]
/// Reset the buffer selector to buffer 0.
RESET: u1 = 0,
/// PID_0 [13:13]
/// The data pid of buffer 0.
PID_0: u1 = 0,
/// LAST_0 [14:14]
/// Buffer 0 is the last buffer of the transfer.
LAST_0: u1 = 0,
/// FULL_0 [15:15]
/// Buffer 0 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_0: u1 = 0,
/// LENGTH_1 [16:25]
/// The length of the data in buffer 1.
LENGTH_1: u10 = 0,
/// AVAILABLE_1 [26:26]
/// Buffer 1 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_1: u1 = 0,
/// DOUBLE_BUFFER_ISO_OFFSET [27:28]
/// The number of bytes buffer 1 is offset from buffer 0 in Isochronous mode. Only valid in double buffered mode for an Isochronous endpoint.\n
DOUBLE_BUFFER_ISO_OFFSET: u2 = 0,
/// PID_1 [29:29]
/// The data pid of buffer 1.
PID_1: u1 = 0,
/// LAST_1 [30:30]
/// Buffer 1 is the last buffer of the transfer.
LAST_1: u1 = 0,
/// FULL_1 [31:31]
/// Buffer 1 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_1: u1 = 0,
};
/// Buffer control for both buffers of an endpoint. Fields ending in a _1 are for buffer 1.\n
pub const EP13_OUT_BUFFER_CONTROL = Register(EP13_OUT_BUFFER_CONTROL_val).init(base_address + 0xec);

/// EP13_IN_BUFFER_CONTROL
const EP13_IN_BUFFER_CONTROL_val = packed struct {
/// LENGTH_0 [0:9]
/// The length of the data in buffer 1.
LENGTH_0: u10 = 0,
/// AVAILABLE_0 [10:10]
/// Buffer 0 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_0: u1 = 0,
/// STALL [11:11]
/// Reply with a stall (valid for both buffers).
STALL: u1 = 0,
/// RESET [12:12]
/// Reset the buffer selector to buffer 0.
RESET: u1 = 0,
/// PID_0 [13:13]
/// The data pid of buffer 0.
PID_0: u1 = 0,
/// LAST_0 [14:14]
/// Buffer 0 is the last buffer of the transfer.
LAST_0: u1 = 0,
/// FULL_0 [15:15]
/// Buffer 0 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_0: u1 = 0,
/// LENGTH_1 [16:25]
/// The length of the data in buffer 1.
LENGTH_1: u10 = 0,
/// AVAILABLE_1 [26:26]
/// Buffer 1 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_1: u1 = 0,
/// DOUBLE_BUFFER_ISO_OFFSET [27:28]
/// The number of bytes buffer 1 is offset from buffer 0 in Isochronous mode. Only valid in double buffered mode for an Isochronous endpoint.\n
DOUBLE_BUFFER_ISO_OFFSET: u2 = 0,
/// PID_1 [29:29]
/// The data pid of buffer 1.
PID_1: u1 = 0,
/// LAST_1 [30:30]
/// Buffer 1 is the last buffer of the transfer.
LAST_1: u1 = 0,
/// FULL_1 [31:31]
/// Buffer 1 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_1: u1 = 0,
};
/// Buffer control for both buffers of an endpoint. Fields ending in a _1 are for buffer 1.\n
pub const EP13_IN_BUFFER_CONTROL = Register(EP13_IN_BUFFER_CONTROL_val).init(base_address + 0xe8);

/// EP12_OUT_BUFFER_CONTROL
const EP12_OUT_BUFFER_CONTROL_val = packed struct {
/// LENGTH_0 [0:9]
/// The length of the data in buffer 1.
LENGTH_0: u10 = 0,
/// AVAILABLE_0 [10:10]
/// Buffer 0 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_0: u1 = 0,
/// STALL [11:11]
/// Reply with a stall (valid for both buffers).
STALL: u1 = 0,
/// RESET [12:12]
/// Reset the buffer selector to buffer 0.
RESET: u1 = 0,
/// PID_0 [13:13]
/// The data pid of buffer 0.
PID_0: u1 = 0,
/// LAST_0 [14:14]
/// Buffer 0 is the last buffer of the transfer.
LAST_0: u1 = 0,
/// FULL_0 [15:15]
/// Buffer 0 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_0: u1 = 0,
/// LENGTH_1 [16:25]
/// The length of the data in buffer 1.
LENGTH_1: u10 = 0,
/// AVAILABLE_1 [26:26]
/// Buffer 1 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_1: u1 = 0,
/// DOUBLE_BUFFER_ISO_OFFSET [27:28]
/// The number of bytes buffer 1 is offset from buffer 0 in Isochronous mode. Only valid in double buffered mode for an Isochronous endpoint.\n
DOUBLE_BUFFER_ISO_OFFSET: u2 = 0,
/// PID_1 [29:29]
/// The data pid of buffer 1.
PID_1: u1 = 0,
/// LAST_1 [30:30]
/// Buffer 1 is the last buffer of the transfer.
LAST_1: u1 = 0,
/// FULL_1 [31:31]
/// Buffer 1 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_1: u1 = 0,
};
/// Buffer control for both buffers of an endpoint. Fields ending in a _1 are for buffer 1.\n
pub const EP12_OUT_BUFFER_CONTROL = Register(EP12_OUT_BUFFER_CONTROL_val).init(base_address + 0xe4);

/// EP12_IN_BUFFER_CONTROL
const EP12_IN_BUFFER_CONTROL_val = packed struct {
/// LENGTH_0 [0:9]
/// The length of the data in buffer 1.
LENGTH_0: u10 = 0,
/// AVAILABLE_0 [10:10]
/// Buffer 0 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_0: u1 = 0,
/// STALL [11:11]
/// Reply with a stall (valid for both buffers).
STALL: u1 = 0,
/// RESET [12:12]
/// Reset the buffer selector to buffer 0.
RESET: u1 = 0,
/// PID_0 [13:13]
/// The data pid of buffer 0.
PID_0: u1 = 0,
/// LAST_0 [14:14]
/// Buffer 0 is the last buffer of the transfer.
LAST_0: u1 = 0,
/// FULL_0 [15:15]
/// Buffer 0 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_0: u1 = 0,
/// LENGTH_1 [16:25]
/// The length of the data in buffer 1.
LENGTH_1: u10 = 0,
/// AVAILABLE_1 [26:26]
/// Buffer 1 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_1: u1 = 0,
/// DOUBLE_BUFFER_ISO_OFFSET [27:28]
/// The number of bytes buffer 1 is offset from buffer 0 in Isochronous mode. Only valid in double buffered mode for an Isochronous endpoint.\n
DOUBLE_BUFFER_ISO_OFFSET: u2 = 0,
/// PID_1 [29:29]
/// The data pid of buffer 1.
PID_1: u1 = 0,
/// LAST_1 [30:30]
/// Buffer 1 is the last buffer of the transfer.
LAST_1: u1 = 0,
/// FULL_1 [31:31]
/// Buffer 1 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_1: u1 = 0,
};
/// Buffer control for both buffers of an endpoint. Fields ending in a _1 are for buffer 1.\n
pub const EP12_IN_BUFFER_CONTROL = Register(EP12_IN_BUFFER_CONTROL_val).init(base_address + 0xe0);

/// EP11_OUT_BUFFER_CONTROL
const EP11_OUT_BUFFER_CONTROL_val = packed struct {
/// LENGTH_0 [0:9]
/// The length of the data in buffer 1.
LENGTH_0: u10 = 0,
/// AVAILABLE_0 [10:10]
/// Buffer 0 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_0: u1 = 0,
/// STALL [11:11]
/// Reply with a stall (valid for both buffers).
STALL: u1 = 0,
/// RESET [12:12]
/// Reset the buffer selector to buffer 0.
RESET: u1 = 0,
/// PID_0 [13:13]
/// The data pid of buffer 0.
PID_0: u1 = 0,
/// LAST_0 [14:14]
/// Buffer 0 is the last buffer of the transfer.
LAST_0: u1 = 0,
/// FULL_0 [15:15]
/// Buffer 0 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_0: u1 = 0,
/// LENGTH_1 [16:25]
/// The length of the data in buffer 1.
LENGTH_1: u10 = 0,
/// AVAILABLE_1 [26:26]
/// Buffer 1 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_1: u1 = 0,
/// DOUBLE_BUFFER_ISO_OFFSET [27:28]
/// The number of bytes buffer 1 is offset from buffer 0 in Isochronous mode. Only valid in double buffered mode for an Isochronous endpoint.\n
DOUBLE_BUFFER_ISO_OFFSET: u2 = 0,
/// PID_1 [29:29]
/// The data pid of buffer 1.
PID_1: u1 = 0,
/// LAST_1 [30:30]
/// Buffer 1 is the last buffer of the transfer.
LAST_1: u1 = 0,
/// FULL_1 [31:31]
/// Buffer 1 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_1: u1 = 0,
};
/// Buffer control for both buffers of an endpoint. Fields ending in a _1 are for buffer 1.\n
pub const EP11_OUT_BUFFER_CONTROL = Register(EP11_OUT_BUFFER_CONTROL_val).init(base_address + 0xdc);

/// EP11_IN_BUFFER_CONTROL
const EP11_IN_BUFFER_CONTROL_val = packed struct {
/// LENGTH_0 [0:9]
/// The length of the data in buffer 1.
LENGTH_0: u10 = 0,
/// AVAILABLE_0 [10:10]
/// Buffer 0 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_0: u1 = 0,
/// STALL [11:11]
/// Reply with a stall (valid for both buffers).
STALL: u1 = 0,
/// RESET [12:12]
/// Reset the buffer selector to buffer 0.
RESET: u1 = 0,
/// PID_0 [13:13]
/// The data pid of buffer 0.
PID_0: u1 = 0,
/// LAST_0 [14:14]
/// Buffer 0 is the last buffer of the transfer.
LAST_0: u1 = 0,
/// FULL_0 [15:15]
/// Buffer 0 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_0: u1 = 0,
/// LENGTH_1 [16:25]
/// The length of the data in buffer 1.
LENGTH_1: u10 = 0,
/// AVAILABLE_1 [26:26]
/// Buffer 1 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_1: u1 = 0,
/// DOUBLE_BUFFER_ISO_OFFSET [27:28]
/// The number of bytes buffer 1 is offset from buffer 0 in Isochronous mode. Only valid in double buffered mode for an Isochronous endpoint.\n
DOUBLE_BUFFER_ISO_OFFSET: u2 = 0,
/// PID_1 [29:29]
/// The data pid of buffer 1.
PID_1: u1 = 0,
/// LAST_1 [30:30]
/// Buffer 1 is the last buffer of the transfer.
LAST_1: u1 = 0,
/// FULL_1 [31:31]
/// Buffer 1 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_1: u1 = 0,
};
/// Buffer control for both buffers of an endpoint. Fields ending in a _1 are for buffer 1.\n
pub const EP11_IN_BUFFER_CONTROL = Register(EP11_IN_BUFFER_CONTROL_val).init(base_address + 0xd8);

/// EP10_OUT_BUFFER_CONTROL
const EP10_OUT_BUFFER_CONTROL_val = packed struct {
/// LENGTH_0 [0:9]
/// The length of the data in buffer 1.
LENGTH_0: u10 = 0,
/// AVAILABLE_0 [10:10]
/// Buffer 0 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_0: u1 = 0,
/// STALL [11:11]
/// Reply with a stall (valid for both buffers).
STALL: u1 = 0,
/// RESET [12:12]
/// Reset the buffer selector to buffer 0.
RESET: u1 = 0,
/// PID_0 [13:13]
/// The data pid of buffer 0.
PID_0: u1 = 0,
/// LAST_0 [14:14]
/// Buffer 0 is the last buffer of the transfer.
LAST_0: u1 = 0,
/// FULL_0 [15:15]
/// Buffer 0 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_0: u1 = 0,
/// LENGTH_1 [16:25]
/// The length of the data in buffer 1.
LENGTH_1: u10 = 0,
/// AVAILABLE_1 [26:26]
/// Buffer 1 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_1: u1 = 0,
/// DOUBLE_BUFFER_ISO_OFFSET [27:28]
/// The number of bytes buffer 1 is offset from buffer 0 in Isochronous mode. Only valid in double buffered mode for an Isochronous endpoint.\n
DOUBLE_BUFFER_ISO_OFFSET: u2 = 0,
/// PID_1 [29:29]
/// The data pid of buffer 1.
PID_1: u1 = 0,
/// LAST_1 [30:30]
/// Buffer 1 is the last buffer of the transfer.
LAST_1: u1 = 0,
/// FULL_1 [31:31]
/// Buffer 1 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_1: u1 = 0,
};
/// Buffer control for both buffers of an endpoint. Fields ending in a _1 are for buffer 1.\n
pub const EP10_OUT_BUFFER_CONTROL = Register(EP10_OUT_BUFFER_CONTROL_val).init(base_address + 0xd4);

/// EP10_IN_BUFFER_CONTROL
const EP10_IN_BUFFER_CONTROL_val = packed struct {
/// LENGTH_0 [0:9]
/// The length of the data in buffer 1.
LENGTH_0: u10 = 0,
/// AVAILABLE_0 [10:10]
/// Buffer 0 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_0: u1 = 0,
/// STALL [11:11]
/// Reply with a stall (valid for both buffers).
STALL: u1 = 0,
/// RESET [12:12]
/// Reset the buffer selector to buffer 0.
RESET: u1 = 0,
/// PID_0 [13:13]
/// The data pid of buffer 0.
PID_0: u1 = 0,
/// LAST_0 [14:14]
/// Buffer 0 is the last buffer of the transfer.
LAST_0: u1 = 0,
/// FULL_0 [15:15]
/// Buffer 0 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_0: u1 = 0,
/// LENGTH_1 [16:25]
/// The length of the data in buffer 1.
LENGTH_1: u10 = 0,
/// AVAILABLE_1 [26:26]
/// Buffer 1 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_1: u1 = 0,
/// DOUBLE_BUFFER_ISO_OFFSET [27:28]
/// The number of bytes buffer 1 is offset from buffer 0 in Isochronous mode. Only valid in double buffered mode for an Isochronous endpoint.\n
DOUBLE_BUFFER_ISO_OFFSET: u2 = 0,
/// PID_1 [29:29]
/// The data pid of buffer 1.
PID_1: u1 = 0,
/// LAST_1 [30:30]
/// Buffer 1 is the last buffer of the transfer.
LAST_1: u1 = 0,
/// FULL_1 [31:31]
/// Buffer 1 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_1: u1 = 0,
};
/// Buffer control for both buffers of an endpoint. Fields ending in a _1 are for buffer 1.\n
pub const EP10_IN_BUFFER_CONTROL = Register(EP10_IN_BUFFER_CONTROL_val).init(base_address + 0xd0);

/// EP9_OUT_BUFFER_CONTROL
const EP9_OUT_BUFFER_CONTROL_val = packed struct {
/// LENGTH_0 [0:9]
/// The length of the data in buffer 1.
LENGTH_0: u10 = 0,
/// AVAILABLE_0 [10:10]
/// Buffer 0 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_0: u1 = 0,
/// STALL [11:11]
/// Reply with a stall (valid for both buffers).
STALL: u1 = 0,
/// RESET [12:12]
/// Reset the buffer selector to buffer 0.
RESET: u1 = 0,
/// PID_0 [13:13]
/// The data pid of buffer 0.
PID_0: u1 = 0,
/// LAST_0 [14:14]
/// Buffer 0 is the last buffer of the transfer.
LAST_0: u1 = 0,
/// FULL_0 [15:15]
/// Buffer 0 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_0: u1 = 0,
/// LENGTH_1 [16:25]
/// The length of the data in buffer 1.
LENGTH_1: u10 = 0,
/// AVAILABLE_1 [26:26]
/// Buffer 1 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_1: u1 = 0,
/// DOUBLE_BUFFER_ISO_OFFSET [27:28]
/// The number of bytes buffer 1 is offset from buffer 0 in Isochronous mode. Only valid in double buffered mode for an Isochronous endpoint.\n
DOUBLE_BUFFER_ISO_OFFSET: u2 = 0,
/// PID_1 [29:29]
/// The data pid of buffer 1.
PID_1: u1 = 0,
/// LAST_1 [30:30]
/// Buffer 1 is the last buffer of the transfer.
LAST_1: u1 = 0,
/// FULL_1 [31:31]
/// Buffer 1 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_1: u1 = 0,
};
/// Buffer control for both buffers of an endpoint. Fields ending in a _1 are for buffer 1.\n
pub const EP9_OUT_BUFFER_CONTROL = Register(EP9_OUT_BUFFER_CONTROL_val).init(base_address + 0xcc);

/// EP9_IN_BUFFER_CONTROL
const EP9_IN_BUFFER_CONTROL_val = packed struct {
/// LENGTH_0 [0:9]
/// The length of the data in buffer 1.
LENGTH_0: u10 = 0,
/// AVAILABLE_0 [10:10]
/// Buffer 0 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_0: u1 = 0,
/// STALL [11:11]
/// Reply with a stall (valid for both buffers).
STALL: u1 = 0,
/// RESET [12:12]
/// Reset the buffer selector to buffer 0.
RESET: u1 = 0,
/// PID_0 [13:13]
/// The data pid of buffer 0.
PID_0: u1 = 0,
/// LAST_0 [14:14]
/// Buffer 0 is the last buffer of the transfer.
LAST_0: u1 = 0,
/// FULL_0 [15:15]
/// Buffer 0 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_0: u1 = 0,
/// LENGTH_1 [16:25]
/// The length of the data in buffer 1.
LENGTH_1: u10 = 0,
/// AVAILABLE_1 [26:26]
/// Buffer 1 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_1: u1 = 0,
/// DOUBLE_BUFFER_ISO_OFFSET [27:28]
/// The number of bytes buffer 1 is offset from buffer 0 in Isochronous mode. Only valid in double buffered mode for an Isochronous endpoint.\n
DOUBLE_BUFFER_ISO_OFFSET: u2 = 0,
/// PID_1 [29:29]
/// The data pid of buffer 1.
PID_1: u1 = 0,
/// LAST_1 [30:30]
/// Buffer 1 is the last buffer of the transfer.
LAST_1: u1 = 0,
/// FULL_1 [31:31]
/// Buffer 1 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_1: u1 = 0,
};
/// Buffer control for both buffers of an endpoint. Fields ending in a _1 are for buffer 1.\n
pub const EP9_IN_BUFFER_CONTROL = Register(EP9_IN_BUFFER_CONTROL_val).init(base_address + 0xc8);

/// EP8_OUT_BUFFER_CONTROL
const EP8_OUT_BUFFER_CONTROL_val = packed struct {
/// LENGTH_0 [0:9]
/// The length of the data in buffer 1.
LENGTH_0: u10 = 0,
/// AVAILABLE_0 [10:10]
/// Buffer 0 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_0: u1 = 0,
/// STALL [11:11]
/// Reply with a stall (valid for both buffers).
STALL: u1 = 0,
/// RESET [12:12]
/// Reset the buffer selector to buffer 0.
RESET: u1 = 0,
/// PID_0 [13:13]
/// The data pid of buffer 0.
PID_0: u1 = 0,
/// LAST_0 [14:14]
/// Buffer 0 is the last buffer of the transfer.
LAST_0: u1 = 0,
/// FULL_0 [15:15]
/// Buffer 0 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_0: u1 = 0,
/// LENGTH_1 [16:25]
/// The length of the data in buffer 1.
LENGTH_1: u10 = 0,
/// AVAILABLE_1 [26:26]
/// Buffer 1 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_1: u1 = 0,
/// DOUBLE_BUFFER_ISO_OFFSET [27:28]
/// The number of bytes buffer 1 is offset from buffer 0 in Isochronous mode. Only valid in double buffered mode for an Isochronous endpoint.\n
DOUBLE_BUFFER_ISO_OFFSET: u2 = 0,
/// PID_1 [29:29]
/// The data pid of buffer 1.
PID_1: u1 = 0,
/// LAST_1 [30:30]
/// Buffer 1 is the last buffer of the transfer.
LAST_1: u1 = 0,
/// FULL_1 [31:31]
/// Buffer 1 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_1: u1 = 0,
};
/// Buffer control for both buffers of an endpoint. Fields ending in a _1 are for buffer 1.\n
pub const EP8_OUT_BUFFER_CONTROL = Register(EP8_OUT_BUFFER_CONTROL_val).init(base_address + 0xc4);

/// EP8_IN_BUFFER_CONTROL
const EP8_IN_BUFFER_CONTROL_val = packed struct {
/// LENGTH_0 [0:9]
/// The length of the data in buffer 1.
LENGTH_0: u10 = 0,
/// AVAILABLE_0 [10:10]
/// Buffer 0 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_0: u1 = 0,
/// STALL [11:11]
/// Reply with a stall (valid for both buffers).
STALL: u1 = 0,
/// RESET [12:12]
/// Reset the buffer selector to buffer 0.
RESET: u1 = 0,
/// PID_0 [13:13]
/// The data pid of buffer 0.
PID_0: u1 = 0,
/// LAST_0 [14:14]
/// Buffer 0 is the last buffer of the transfer.
LAST_0: u1 = 0,
/// FULL_0 [15:15]
/// Buffer 0 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_0: u1 = 0,
/// LENGTH_1 [16:25]
/// The length of the data in buffer 1.
LENGTH_1: u10 = 0,
/// AVAILABLE_1 [26:26]
/// Buffer 1 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_1: u1 = 0,
/// DOUBLE_BUFFER_ISO_OFFSET [27:28]
/// The number of bytes buffer 1 is offset from buffer 0 in Isochronous mode. Only valid in double buffered mode for an Isochronous endpoint.\n
DOUBLE_BUFFER_ISO_OFFSET: u2 = 0,
/// PID_1 [29:29]
/// The data pid of buffer 1.
PID_1: u1 = 0,
/// LAST_1 [30:30]
/// Buffer 1 is the last buffer of the transfer.
LAST_1: u1 = 0,
/// FULL_1 [31:31]
/// Buffer 1 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_1: u1 = 0,
};
/// Buffer control for both buffers of an endpoint. Fields ending in a _1 are for buffer 1.\n
pub const EP8_IN_BUFFER_CONTROL = Register(EP8_IN_BUFFER_CONTROL_val).init(base_address + 0xc0);

/// EP7_OUT_BUFFER_CONTROL
const EP7_OUT_BUFFER_CONTROL_val = packed struct {
/// LENGTH_0 [0:9]
/// The length of the data in buffer 1.
LENGTH_0: u10 = 0,
/// AVAILABLE_0 [10:10]
/// Buffer 0 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_0: u1 = 0,
/// STALL [11:11]
/// Reply with a stall (valid for both buffers).
STALL: u1 = 0,
/// RESET [12:12]
/// Reset the buffer selector to buffer 0.
RESET: u1 = 0,
/// PID_0 [13:13]
/// The data pid of buffer 0.
PID_0: u1 = 0,
/// LAST_0 [14:14]
/// Buffer 0 is the last buffer of the transfer.
LAST_0: u1 = 0,
/// FULL_0 [15:15]
/// Buffer 0 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_0: u1 = 0,
/// LENGTH_1 [16:25]
/// The length of the data in buffer 1.
LENGTH_1: u10 = 0,
/// AVAILABLE_1 [26:26]
/// Buffer 1 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_1: u1 = 0,
/// DOUBLE_BUFFER_ISO_OFFSET [27:28]
/// The number of bytes buffer 1 is offset from buffer 0 in Isochronous mode. Only valid in double buffered mode for an Isochronous endpoint.\n
DOUBLE_BUFFER_ISO_OFFSET: u2 = 0,
/// PID_1 [29:29]
/// The data pid of buffer 1.
PID_1: u1 = 0,
/// LAST_1 [30:30]
/// Buffer 1 is the last buffer of the transfer.
LAST_1: u1 = 0,
/// FULL_1 [31:31]
/// Buffer 1 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_1: u1 = 0,
};
/// Buffer control for both buffers of an endpoint. Fields ending in a _1 are for buffer 1.\n
pub const EP7_OUT_BUFFER_CONTROL = Register(EP7_OUT_BUFFER_CONTROL_val).init(base_address + 0xbc);

/// EP7_IN_BUFFER_CONTROL
const EP7_IN_BUFFER_CONTROL_val = packed struct {
/// LENGTH_0 [0:9]
/// The length of the data in buffer 1.
LENGTH_0: u10 = 0,
/// AVAILABLE_0 [10:10]
/// Buffer 0 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_0: u1 = 0,
/// STALL [11:11]
/// Reply with a stall (valid for both buffers).
STALL: u1 = 0,
/// RESET [12:12]
/// Reset the buffer selector to buffer 0.
RESET: u1 = 0,
/// PID_0 [13:13]
/// The data pid of buffer 0.
PID_0: u1 = 0,
/// LAST_0 [14:14]
/// Buffer 0 is the last buffer of the transfer.
LAST_0: u1 = 0,
/// FULL_0 [15:15]
/// Buffer 0 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_0: u1 = 0,
/// LENGTH_1 [16:25]
/// The length of the data in buffer 1.
LENGTH_1: u10 = 0,
/// AVAILABLE_1 [26:26]
/// Buffer 1 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_1: u1 = 0,
/// DOUBLE_BUFFER_ISO_OFFSET [27:28]
/// The number of bytes buffer 1 is offset from buffer 0 in Isochronous mode. Only valid in double buffered mode for an Isochronous endpoint.\n
DOUBLE_BUFFER_ISO_OFFSET: u2 = 0,
/// PID_1 [29:29]
/// The data pid of buffer 1.
PID_1: u1 = 0,
/// LAST_1 [30:30]
/// Buffer 1 is the last buffer of the transfer.
LAST_1: u1 = 0,
/// FULL_1 [31:31]
/// Buffer 1 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_1: u1 = 0,
};
/// Buffer control for both buffers of an endpoint. Fields ending in a _1 are for buffer 1.\n
pub const EP7_IN_BUFFER_CONTROL = Register(EP7_IN_BUFFER_CONTROL_val).init(base_address + 0xb8);

/// EP6_OUT_BUFFER_CONTROL
const EP6_OUT_BUFFER_CONTROL_val = packed struct {
/// LENGTH_0 [0:9]
/// The length of the data in buffer 1.
LENGTH_0: u10 = 0,
/// AVAILABLE_0 [10:10]
/// Buffer 0 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_0: u1 = 0,
/// STALL [11:11]
/// Reply with a stall (valid for both buffers).
STALL: u1 = 0,
/// RESET [12:12]
/// Reset the buffer selector to buffer 0.
RESET: u1 = 0,
/// PID_0 [13:13]
/// The data pid of buffer 0.
PID_0: u1 = 0,
/// LAST_0 [14:14]
/// Buffer 0 is the last buffer of the transfer.
LAST_0: u1 = 0,
/// FULL_0 [15:15]
/// Buffer 0 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_0: u1 = 0,
/// LENGTH_1 [16:25]
/// The length of the data in buffer 1.
LENGTH_1: u10 = 0,
/// AVAILABLE_1 [26:26]
/// Buffer 1 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_1: u1 = 0,
/// DOUBLE_BUFFER_ISO_OFFSET [27:28]
/// The number of bytes buffer 1 is offset from buffer 0 in Isochronous mode. Only valid in double buffered mode for an Isochronous endpoint.\n
DOUBLE_BUFFER_ISO_OFFSET: u2 = 0,
/// PID_1 [29:29]
/// The data pid of buffer 1.
PID_1: u1 = 0,
/// LAST_1 [30:30]
/// Buffer 1 is the last buffer of the transfer.
LAST_1: u1 = 0,
/// FULL_1 [31:31]
/// Buffer 1 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_1: u1 = 0,
};
/// Buffer control for both buffers of an endpoint. Fields ending in a _1 are for buffer 1.\n
pub const EP6_OUT_BUFFER_CONTROL = Register(EP6_OUT_BUFFER_CONTROL_val).init(base_address + 0xb4);

/// EP6_IN_BUFFER_CONTROL
const EP6_IN_BUFFER_CONTROL_val = packed struct {
/// LENGTH_0 [0:9]
/// The length of the data in buffer 1.
LENGTH_0: u10 = 0,
/// AVAILABLE_0 [10:10]
/// Buffer 0 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_0: u1 = 0,
/// STALL [11:11]
/// Reply with a stall (valid for both buffers).
STALL: u1 = 0,
/// RESET [12:12]
/// Reset the buffer selector to buffer 0.
RESET: u1 = 0,
/// PID_0 [13:13]
/// The data pid of buffer 0.
PID_0: u1 = 0,
/// LAST_0 [14:14]
/// Buffer 0 is the last buffer of the transfer.
LAST_0: u1 = 0,
/// FULL_0 [15:15]
/// Buffer 0 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_0: u1 = 0,
/// LENGTH_1 [16:25]
/// The length of the data in buffer 1.
LENGTH_1: u10 = 0,
/// AVAILABLE_1 [26:26]
/// Buffer 1 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_1: u1 = 0,
/// DOUBLE_BUFFER_ISO_OFFSET [27:28]
/// The number of bytes buffer 1 is offset from buffer 0 in Isochronous mode. Only valid in double buffered mode for an Isochronous endpoint.\n
DOUBLE_BUFFER_ISO_OFFSET: u2 = 0,
/// PID_1 [29:29]
/// The data pid of buffer 1.
PID_1: u1 = 0,
/// LAST_1 [30:30]
/// Buffer 1 is the last buffer of the transfer.
LAST_1: u1 = 0,
/// FULL_1 [31:31]
/// Buffer 1 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_1: u1 = 0,
};
/// Buffer control for both buffers of an endpoint. Fields ending in a _1 are for buffer 1.\n
pub const EP6_IN_BUFFER_CONTROL = Register(EP6_IN_BUFFER_CONTROL_val).init(base_address + 0xb0);

/// EP5_OUT_BUFFER_CONTROL
const EP5_OUT_BUFFER_CONTROL_val = packed struct {
/// LENGTH_0 [0:9]
/// The length of the data in buffer 1.
LENGTH_0: u10 = 0,
/// AVAILABLE_0 [10:10]
/// Buffer 0 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_0: u1 = 0,
/// STALL [11:11]
/// Reply with a stall (valid for both buffers).
STALL: u1 = 0,
/// RESET [12:12]
/// Reset the buffer selector to buffer 0.
RESET: u1 = 0,
/// PID_0 [13:13]
/// The data pid of buffer 0.
PID_0: u1 = 0,
/// LAST_0 [14:14]
/// Buffer 0 is the last buffer of the transfer.
LAST_0: u1 = 0,
/// FULL_0 [15:15]
/// Buffer 0 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_0: u1 = 0,
/// LENGTH_1 [16:25]
/// The length of the data in buffer 1.
LENGTH_1: u10 = 0,
/// AVAILABLE_1 [26:26]
/// Buffer 1 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_1: u1 = 0,
/// DOUBLE_BUFFER_ISO_OFFSET [27:28]
/// The number of bytes buffer 1 is offset from buffer 0 in Isochronous mode. Only valid in double buffered mode for an Isochronous endpoint.\n
DOUBLE_BUFFER_ISO_OFFSET: u2 = 0,
/// PID_1 [29:29]
/// The data pid of buffer 1.
PID_1: u1 = 0,
/// LAST_1 [30:30]
/// Buffer 1 is the last buffer of the transfer.
LAST_1: u1 = 0,
/// FULL_1 [31:31]
/// Buffer 1 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_1: u1 = 0,
};
/// Buffer control for both buffers of an endpoint. Fields ending in a _1 are for buffer 1.\n
pub const EP5_OUT_BUFFER_CONTROL = Register(EP5_OUT_BUFFER_CONTROL_val).init(base_address + 0xac);

/// EP5_IN_BUFFER_CONTROL
const EP5_IN_BUFFER_CONTROL_val = packed struct {
/// LENGTH_0 [0:9]
/// The length of the data in buffer 1.
LENGTH_0: u10 = 0,
/// AVAILABLE_0 [10:10]
/// Buffer 0 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_0: u1 = 0,
/// STALL [11:11]
/// Reply with a stall (valid for both buffers).
STALL: u1 = 0,
/// RESET [12:12]
/// Reset the buffer selector to buffer 0.
RESET: u1 = 0,
/// PID_0 [13:13]
/// The data pid of buffer 0.
PID_0: u1 = 0,
/// LAST_0 [14:14]
/// Buffer 0 is the last buffer of the transfer.
LAST_0: u1 = 0,
/// FULL_0 [15:15]
/// Buffer 0 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_0: u1 = 0,
/// LENGTH_1 [16:25]
/// The length of the data in buffer 1.
LENGTH_1: u10 = 0,
/// AVAILABLE_1 [26:26]
/// Buffer 1 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_1: u1 = 0,
/// DOUBLE_BUFFER_ISO_OFFSET [27:28]
/// The number of bytes buffer 1 is offset from buffer 0 in Isochronous mode. Only valid in double buffered mode for an Isochronous endpoint.\n
DOUBLE_BUFFER_ISO_OFFSET: u2 = 0,
/// PID_1 [29:29]
/// The data pid of buffer 1.
PID_1: u1 = 0,
/// LAST_1 [30:30]
/// Buffer 1 is the last buffer of the transfer.
LAST_1: u1 = 0,
/// FULL_1 [31:31]
/// Buffer 1 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_1: u1 = 0,
};
/// Buffer control for both buffers of an endpoint. Fields ending in a _1 are for buffer 1.\n
pub const EP5_IN_BUFFER_CONTROL = Register(EP5_IN_BUFFER_CONTROL_val).init(base_address + 0xa8);

/// EP4_OUT_BUFFER_CONTROL
const EP4_OUT_BUFFER_CONTROL_val = packed struct {
/// LENGTH_0 [0:9]
/// The length of the data in buffer 1.
LENGTH_0: u10 = 0,
/// AVAILABLE_0 [10:10]
/// Buffer 0 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_0: u1 = 0,
/// STALL [11:11]
/// Reply with a stall (valid for both buffers).
STALL: u1 = 0,
/// RESET [12:12]
/// Reset the buffer selector to buffer 0.
RESET: u1 = 0,
/// PID_0 [13:13]
/// The data pid of buffer 0.
PID_0: u1 = 0,
/// LAST_0 [14:14]
/// Buffer 0 is the last buffer of the transfer.
LAST_0: u1 = 0,
/// FULL_0 [15:15]
/// Buffer 0 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_0: u1 = 0,
/// LENGTH_1 [16:25]
/// The length of the data in buffer 1.
LENGTH_1: u10 = 0,
/// AVAILABLE_1 [26:26]
/// Buffer 1 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_1: u1 = 0,
/// DOUBLE_BUFFER_ISO_OFFSET [27:28]
/// The number of bytes buffer 1 is offset from buffer 0 in Isochronous mode. Only valid in double buffered mode for an Isochronous endpoint.\n
DOUBLE_BUFFER_ISO_OFFSET: u2 = 0,
/// PID_1 [29:29]
/// The data pid of buffer 1.
PID_1: u1 = 0,
/// LAST_1 [30:30]
/// Buffer 1 is the last buffer of the transfer.
LAST_1: u1 = 0,
/// FULL_1 [31:31]
/// Buffer 1 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_1: u1 = 0,
};
/// Buffer control for both buffers of an endpoint. Fields ending in a _1 are for buffer 1.\n
pub const EP4_OUT_BUFFER_CONTROL = Register(EP4_OUT_BUFFER_CONTROL_val).init(base_address + 0xa4);

/// EP4_IN_BUFFER_CONTROL
const EP4_IN_BUFFER_CONTROL_val = packed struct {
/// LENGTH_0 [0:9]
/// The length of the data in buffer 1.
LENGTH_0: u10 = 0,
/// AVAILABLE_0 [10:10]
/// Buffer 0 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_0: u1 = 0,
/// STALL [11:11]
/// Reply with a stall (valid for both buffers).
STALL: u1 = 0,
/// RESET [12:12]
/// Reset the buffer selector to buffer 0.
RESET: u1 = 0,
/// PID_0 [13:13]
/// The data pid of buffer 0.
PID_0: u1 = 0,
/// LAST_0 [14:14]
/// Buffer 0 is the last buffer of the transfer.
LAST_0: u1 = 0,
/// FULL_0 [15:15]
/// Buffer 0 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_0: u1 = 0,
/// LENGTH_1 [16:25]
/// The length of the data in buffer 1.
LENGTH_1: u10 = 0,
/// AVAILABLE_1 [26:26]
/// Buffer 1 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_1: u1 = 0,
/// DOUBLE_BUFFER_ISO_OFFSET [27:28]
/// The number of bytes buffer 1 is offset from buffer 0 in Isochronous mode. Only valid in double buffered mode for an Isochronous endpoint.\n
DOUBLE_BUFFER_ISO_OFFSET: u2 = 0,
/// PID_1 [29:29]
/// The data pid of buffer 1.
PID_1: u1 = 0,
/// LAST_1 [30:30]
/// Buffer 1 is the last buffer of the transfer.
LAST_1: u1 = 0,
/// FULL_1 [31:31]
/// Buffer 1 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_1: u1 = 0,
};
/// Buffer control for both buffers of an endpoint. Fields ending in a _1 are for buffer 1.\n
pub const EP4_IN_BUFFER_CONTROL = Register(EP4_IN_BUFFER_CONTROL_val).init(base_address + 0xa0);

/// EP3_OUT_BUFFER_CONTROL
const EP3_OUT_BUFFER_CONTROL_val = packed struct {
/// LENGTH_0 [0:9]
/// The length of the data in buffer 1.
LENGTH_0: u10 = 0,
/// AVAILABLE_0 [10:10]
/// Buffer 0 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_0: u1 = 0,
/// STALL [11:11]
/// Reply with a stall (valid for both buffers).
STALL: u1 = 0,
/// RESET [12:12]
/// Reset the buffer selector to buffer 0.
RESET: u1 = 0,
/// PID_0 [13:13]
/// The data pid of buffer 0.
PID_0: u1 = 0,
/// LAST_0 [14:14]
/// Buffer 0 is the last buffer of the transfer.
LAST_0: u1 = 0,
/// FULL_0 [15:15]
/// Buffer 0 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_0: u1 = 0,
/// LENGTH_1 [16:25]
/// The length of the data in buffer 1.
LENGTH_1: u10 = 0,
/// AVAILABLE_1 [26:26]
/// Buffer 1 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_1: u1 = 0,
/// DOUBLE_BUFFER_ISO_OFFSET [27:28]
/// The number of bytes buffer 1 is offset from buffer 0 in Isochronous mode. Only valid in double buffered mode for an Isochronous endpoint.\n
DOUBLE_BUFFER_ISO_OFFSET: u2 = 0,
/// PID_1 [29:29]
/// The data pid of buffer 1.
PID_1: u1 = 0,
/// LAST_1 [30:30]
/// Buffer 1 is the last buffer of the transfer.
LAST_1: u1 = 0,
/// FULL_1 [31:31]
/// Buffer 1 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_1: u1 = 0,
};
/// Buffer control for both buffers of an endpoint. Fields ending in a _1 are for buffer 1.\n
pub const EP3_OUT_BUFFER_CONTROL = Register(EP3_OUT_BUFFER_CONTROL_val).init(base_address + 0x9c);

/// EP3_IN_BUFFER_CONTROL
const EP3_IN_BUFFER_CONTROL_val = packed struct {
/// LENGTH_0 [0:9]
/// The length of the data in buffer 1.
LENGTH_0: u10 = 0,
/// AVAILABLE_0 [10:10]
/// Buffer 0 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_0: u1 = 0,
/// STALL [11:11]
/// Reply with a stall (valid for both buffers).
STALL: u1 = 0,
/// RESET [12:12]
/// Reset the buffer selector to buffer 0.
RESET: u1 = 0,
/// PID_0 [13:13]
/// The data pid of buffer 0.
PID_0: u1 = 0,
/// LAST_0 [14:14]
/// Buffer 0 is the last buffer of the transfer.
LAST_0: u1 = 0,
/// FULL_0 [15:15]
/// Buffer 0 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_0: u1 = 0,
/// LENGTH_1 [16:25]
/// The length of the data in buffer 1.
LENGTH_1: u10 = 0,
/// AVAILABLE_1 [26:26]
/// Buffer 1 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_1: u1 = 0,
/// DOUBLE_BUFFER_ISO_OFFSET [27:28]
/// The number of bytes buffer 1 is offset from buffer 0 in Isochronous mode. Only valid in double buffered mode for an Isochronous endpoint.\n
DOUBLE_BUFFER_ISO_OFFSET: u2 = 0,
/// PID_1 [29:29]
/// The data pid of buffer 1.
PID_1: u1 = 0,
/// LAST_1 [30:30]
/// Buffer 1 is the last buffer of the transfer.
LAST_1: u1 = 0,
/// FULL_1 [31:31]
/// Buffer 1 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_1: u1 = 0,
};
/// Buffer control for both buffers of an endpoint. Fields ending in a _1 are for buffer 1.\n
pub const EP3_IN_BUFFER_CONTROL = Register(EP3_IN_BUFFER_CONTROL_val).init(base_address + 0x98);

/// EP2_OUT_BUFFER_CONTROL
const EP2_OUT_BUFFER_CONTROL_val = packed struct {
/// LENGTH_0 [0:9]
/// The length of the data in buffer 1.
LENGTH_0: u10 = 0,
/// AVAILABLE_0 [10:10]
/// Buffer 0 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_0: u1 = 0,
/// STALL [11:11]
/// Reply with a stall (valid for both buffers).
STALL: u1 = 0,
/// RESET [12:12]
/// Reset the buffer selector to buffer 0.
RESET: u1 = 0,
/// PID_0 [13:13]
/// The data pid of buffer 0.
PID_0: u1 = 0,
/// LAST_0 [14:14]
/// Buffer 0 is the last buffer of the transfer.
LAST_0: u1 = 0,
/// FULL_0 [15:15]
/// Buffer 0 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_0: u1 = 0,
/// LENGTH_1 [16:25]
/// The length of the data in buffer 1.
LENGTH_1: u10 = 0,
/// AVAILABLE_1 [26:26]
/// Buffer 1 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_1: u1 = 0,
/// DOUBLE_BUFFER_ISO_OFFSET [27:28]
/// The number of bytes buffer 1 is offset from buffer 0 in Isochronous mode. Only valid in double buffered mode for an Isochronous endpoint.\n
DOUBLE_BUFFER_ISO_OFFSET: u2 = 0,
/// PID_1 [29:29]
/// The data pid of buffer 1.
PID_1: u1 = 0,
/// LAST_1 [30:30]
/// Buffer 1 is the last buffer of the transfer.
LAST_1: u1 = 0,
/// FULL_1 [31:31]
/// Buffer 1 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_1: u1 = 0,
};
/// Buffer control for both buffers of an endpoint. Fields ending in a _1 are for buffer 1.\n
pub const EP2_OUT_BUFFER_CONTROL = Register(EP2_OUT_BUFFER_CONTROL_val).init(base_address + 0x94);

/// EP2_IN_BUFFER_CONTROL
const EP2_IN_BUFFER_CONTROL_val = packed struct {
/// LENGTH_0 [0:9]
/// The length of the data in buffer 1.
LENGTH_0: u10 = 0,
/// AVAILABLE_0 [10:10]
/// Buffer 0 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_0: u1 = 0,
/// STALL [11:11]
/// Reply with a stall (valid for both buffers).
STALL: u1 = 0,
/// RESET [12:12]
/// Reset the buffer selector to buffer 0.
RESET: u1 = 0,
/// PID_0 [13:13]
/// The data pid of buffer 0.
PID_0: u1 = 0,
/// LAST_0 [14:14]
/// Buffer 0 is the last buffer of the transfer.
LAST_0: u1 = 0,
/// FULL_0 [15:15]
/// Buffer 0 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_0: u1 = 0,
/// LENGTH_1 [16:25]
/// The length of the data in buffer 1.
LENGTH_1: u10 = 0,
/// AVAILABLE_1 [26:26]
/// Buffer 1 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_1: u1 = 0,
/// DOUBLE_BUFFER_ISO_OFFSET [27:28]
/// The number of bytes buffer 1 is offset from buffer 0 in Isochronous mode. Only valid in double buffered mode for an Isochronous endpoint.\n
DOUBLE_BUFFER_ISO_OFFSET: u2 = 0,
/// PID_1 [29:29]
/// The data pid of buffer 1.
PID_1: u1 = 0,
/// LAST_1 [30:30]
/// Buffer 1 is the last buffer of the transfer.
LAST_1: u1 = 0,
/// FULL_1 [31:31]
/// Buffer 1 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_1: u1 = 0,
};
/// Buffer control for both buffers of an endpoint. Fields ending in a _1 are for buffer 1.\n
pub const EP2_IN_BUFFER_CONTROL = Register(EP2_IN_BUFFER_CONTROL_val).init(base_address + 0x90);

/// EP1_OUT_BUFFER_CONTROL
const EP1_OUT_BUFFER_CONTROL_val = packed struct {
/// LENGTH_0 [0:9]
/// The length of the data in buffer 1.
LENGTH_0: u10 = 0,
/// AVAILABLE_0 [10:10]
/// Buffer 0 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_0: u1 = 0,
/// STALL [11:11]
/// Reply with a stall (valid for both buffers).
STALL: u1 = 0,
/// RESET [12:12]
/// Reset the buffer selector to buffer 0.
RESET: u1 = 0,
/// PID_0 [13:13]
/// The data pid of buffer 0.
PID_0: u1 = 0,
/// LAST_0 [14:14]
/// Buffer 0 is the last buffer of the transfer.
LAST_0: u1 = 0,
/// FULL_0 [15:15]
/// Buffer 0 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_0: u1 = 0,
/// LENGTH_1 [16:25]
/// The length of the data in buffer 1.
LENGTH_1: u10 = 0,
/// AVAILABLE_1 [26:26]
/// Buffer 1 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_1: u1 = 0,
/// DOUBLE_BUFFER_ISO_OFFSET [27:28]
/// The number of bytes buffer 1 is offset from buffer 0 in Isochronous mode. Only valid in double buffered mode for an Isochronous endpoint.\n
DOUBLE_BUFFER_ISO_OFFSET: u2 = 0,
/// PID_1 [29:29]
/// The data pid of buffer 1.
PID_1: u1 = 0,
/// LAST_1 [30:30]
/// Buffer 1 is the last buffer of the transfer.
LAST_1: u1 = 0,
/// FULL_1 [31:31]
/// Buffer 1 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_1: u1 = 0,
};
/// Buffer control for both buffers of an endpoint. Fields ending in a _1 are for buffer 1.\n
pub const EP1_OUT_BUFFER_CONTROL = Register(EP1_OUT_BUFFER_CONTROL_val).init(base_address + 0x8c);

/// EP1_IN_BUFFER_CONTROL
const EP1_IN_BUFFER_CONTROL_val = packed struct {
/// LENGTH_0 [0:9]
/// The length of the data in buffer 1.
LENGTH_0: u10 = 0,
/// AVAILABLE_0 [10:10]
/// Buffer 0 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_0: u1 = 0,
/// STALL [11:11]
/// Reply with a stall (valid for both buffers).
STALL: u1 = 0,
/// RESET [12:12]
/// Reset the buffer selector to buffer 0.
RESET: u1 = 0,
/// PID_0 [13:13]
/// The data pid of buffer 0.
PID_0: u1 = 0,
/// LAST_0 [14:14]
/// Buffer 0 is the last buffer of the transfer.
LAST_0: u1 = 0,
/// FULL_0 [15:15]
/// Buffer 0 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_0: u1 = 0,
/// LENGTH_1 [16:25]
/// The length of the data in buffer 1.
LENGTH_1: u10 = 0,
/// AVAILABLE_1 [26:26]
/// Buffer 1 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_1: u1 = 0,
/// DOUBLE_BUFFER_ISO_OFFSET [27:28]
/// The number of bytes buffer 1 is offset from buffer 0 in Isochronous mode. Only valid in double buffered mode for an Isochronous endpoint.\n
DOUBLE_BUFFER_ISO_OFFSET: u2 = 0,
/// PID_1 [29:29]
/// The data pid of buffer 1.
PID_1: u1 = 0,
/// LAST_1 [30:30]
/// Buffer 1 is the last buffer of the transfer.
LAST_1: u1 = 0,
/// FULL_1 [31:31]
/// Buffer 1 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_1: u1 = 0,
};
/// Buffer control for both buffers of an endpoint. Fields ending in a _1 are for buffer 1.\n
pub const EP1_IN_BUFFER_CONTROL = Register(EP1_IN_BUFFER_CONTROL_val).init(base_address + 0x88);

/// EP0_OUT_BUFFER_CONTROL
const EP0_OUT_BUFFER_CONTROL_val = packed struct {
/// LENGTH_0 [0:9]
/// The length of the data in buffer 1.
LENGTH_0: u10 = 0,
/// AVAILABLE_0 [10:10]
/// Buffer 0 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_0: u1 = 0,
/// STALL [11:11]
/// Reply with a stall (valid for both buffers).
STALL: u1 = 0,
/// RESET [12:12]
/// Reset the buffer selector to buffer 0.
RESET: u1 = 0,
/// PID_0 [13:13]
/// The data pid of buffer 0.
PID_0: u1 = 0,
/// LAST_0 [14:14]
/// Buffer 0 is the last buffer of the transfer.
LAST_0: u1 = 0,
/// FULL_0 [15:15]
/// Buffer 0 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_0: u1 = 0,
/// LENGTH_1 [16:25]
/// The length of the data in buffer 1.
LENGTH_1: u10 = 0,
/// AVAILABLE_1 [26:26]
/// Buffer 1 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_1: u1 = 0,
/// DOUBLE_BUFFER_ISO_OFFSET [27:28]
/// The number of bytes buffer 1 is offset from buffer 0 in Isochronous mode. Only valid in double buffered mode for an Isochronous endpoint.\n
DOUBLE_BUFFER_ISO_OFFSET: u2 = 0,
/// PID_1 [29:29]
/// The data pid of buffer 1.
PID_1: u1 = 0,
/// LAST_1 [30:30]
/// Buffer 1 is the last buffer of the transfer.
LAST_1: u1 = 0,
/// FULL_1 [31:31]
/// Buffer 1 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_1: u1 = 0,
};
/// Buffer control for both buffers of an endpoint. Fields ending in a _1 are for buffer 1.\n
pub const EP0_OUT_BUFFER_CONTROL = Register(EP0_OUT_BUFFER_CONTROL_val).init(base_address + 0x84);

/// EP0_IN_BUFFER_CONTROL
const EP0_IN_BUFFER_CONTROL_val = packed struct {
/// LENGTH_0 [0:9]
/// The length of the data in buffer 1.
LENGTH_0: u10 = 0,
/// AVAILABLE_0 [10:10]
/// Buffer 0 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_0: u1 = 0,
/// STALL [11:11]
/// Reply with a stall (valid for both buffers).
STALL: u1 = 0,
/// RESET [12:12]
/// Reset the buffer selector to buffer 0.
RESET: u1 = 0,
/// PID_0 [13:13]
/// The data pid of buffer 0.
PID_0: u1 = 0,
/// LAST_0 [14:14]
/// Buffer 0 is the last buffer of the transfer.
LAST_0: u1 = 0,
/// FULL_0 [15:15]
/// Buffer 0 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_0: u1 = 0,
/// LENGTH_1 [16:25]
/// The length of the data in buffer 1.
LENGTH_1: u10 = 0,
/// AVAILABLE_1 [26:26]
/// Buffer 1 is available. This bit is set to indicate the buffer can be used by the controller. The controller clears the available bit when writing the status back.
AVAILABLE_1: u1 = 0,
/// DOUBLE_BUFFER_ISO_OFFSET [27:28]
/// The number of bytes buffer 1 is offset from buffer 0 in Isochronous mode. Only valid in double buffered mode for an Isochronous endpoint.\n
DOUBLE_BUFFER_ISO_OFFSET: u2 = 0,
/// PID_1 [29:29]
/// The data pid of buffer 1.
PID_1: u1 = 0,
/// LAST_1 [30:30]
/// Buffer 1 is the last buffer of the transfer.
LAST_1: u1 = 0,
/// FULL_1 [31:31]
/// Buffer 1 is full. For an IN transfer (TX to the host) the bit is set to indicate the data is valid. For an OUT transfer (RX from the host) this bit should be left as a 0. The host will set it when it has filled the buffer with data.
FULL_1: u1 = 0,
};
/// Buffer control for both buffers of an endpoint. Fields ending in a _1 are for buffer 1.\n
pub const EP0_IN_BUFFER_CONTROL = Register(EP0_IN_BUFFER_CONTROL_val).init(base_address + 0x80);

/// EP15_OUT_CONTROL
const EP15_OUT_CONTROL_val = packed struct {
/// BUFFER_ADDRESS [0:15]
/// 64 byte aligned buffer address for this EP (bits 0-5 are ignored). Relative to the start of the DPRAM.
BUFFER_ADDRESS: u16 = 0,
/// INTERRUPT_ON_NAK [16:16]
/// Trigger an interrupt if a NAK is sent. Intended for debug only.
INTERRUPT_ON_NAK: u1 = 0,
/// INTERRUPT_ON_STALL [17:17]
/// Trigger an interrupt if a STALL is sent. Intended for debug only.
INTERRUPT_ON_STALL: u1 = 0,
/// unused [18:25]
_unused18: u6 = 0,
_unused24: u2 = 0,
/// ENDPOINT_TYPE [26:27]
/// No description
ENDPOINT_TYPE: u2 = 0,
/// INTERRUPT_PER_DOUBLE_BUFF [28:28]
/// Trigger an interrupt each time both buffers are done. Only valid in double buffered mode.
INTERRUPT_PER_DOUBLE_BUFF: u1 = 0,
/// INTERRUPT_PER_BUFF [29:29]
/// Trigger an interrupt each time a buffer is done.
INTERRUPT_PER_BUFF: u1 = 0,
/// DOUBLE_BUFFERED [30:30]
/// This endpoint is double buffered.
DOUBLE_BUFFERED: u1 = 0,
/// ENABLE [31:31]
/// Enable this endpoint. The device will not reply to any packets for this endpoint if this bit is not set.
ENABLE: u1 = 0,
};
/// No description
pub const EP15_OUT_CONTROL = Register(EP15_OUT_CONTROL_val).init(base_address + 0x7c);

/// EP15_IN_CONTROL
const EP15_IN_CONTROL_val = packed struct {
/// BUFFER_ADDRESS [0:15]
/// 64 byte aligned buffer address for this EP (bits 0-5 are ignored). Relative to the start of the DPRAM.
BUFFER_ADDRESS: u16 = 0,
/// INTERRUPT_ON_NAK [16:16]
/// Trigger an interrupt if a NAK is sent. Intended for debug only.
INTERRUPT_ON_NAK: u1 = 0,
/// INTERRUPT_ON_STALL [17:17]
/// Trigger an interrupt if a STALL is sent. Intended for debug only.
INTERRUPT_ON_STALL: u1 = 0,
/// unused [18:25]
_unused18: u6 = 0,
_unused24: u2 = 0,
/// ENDPOINT_TYPE [26:27]
/// No description
ENDPOINT_TYPE: u2 = 0,
/// INTERRUPT_PER_DOUBLE_BUFF [28:28]
/// Trigger an interrupt each time both buffers are done. Only valid in double buffered mode.
INTERRUPT_PER_DOUBLE_BUFF: u1 = 0,
/// INTERRUPT_PER_BUFF [29:29]
/// Trigger an interrupt each time a buffer is done.
INTERRUPT_PER_BUFF: u1 = 0,
/// DOUBLE_BUFFERED [30:30]
/// This endpoint is double buffered.
DOUBLE_BUFFERED: u1 = 0,
/// ENABLE [31:31]
/// Enable this endpoint. The device will not reply to any packets for this endpoint if this bit is not set.
ENABLE: u1 = 0,
};
/// No description
pub const EP15_IN_CONTROL = Register(EP15_IN_CONTROL_val).init(base_address + 0x78);

/// EP14_OUT_CONTROL
const EP14_OUT_CONTROL_val = packed struct {
/// BUFFER_ADDRESS [0:15]
/// 64 byte aligned buffer address for this EP (bits 0-5 are ignored). Relative to the start of the DPRAM.
BUFFER_ADDRESS: u16 = 0,
/// INTERRUPT_ON_NAK [16:16]
/// Trigger an interrupt if a NAK is sent. Intended for debug only.
INTERRUPT_ON_NAK: u1 = 0,
/// INTERRUPT_ON_STALL [17:17]
/// Trigger an interrupt if a STALL is sent. Intended for debug only.
INTERRUPT_ON_STALL: u1 = 0,
/// unused [18:25]
_unused18: u6 = 0,
_unused24: u2 = 0,
/// ENDPOINT_TYPE [26:27]
/// No description
ENDPOINT_TYPE: u2 = 0,
/// INTERRUPT_PER_DOUBLE_BUFF [28:28]
/// Trigger an interrupt each time both buffers are done. Only valid in double buffered mode.
INTERRUPT_PER_DOUBLE_BUFF: u1 = 0,
/// INTERRUPT_PER_BUFF [29:29]
/// Trigger an interrupt each time a buffer is done.
INTERRUPT_PER_BUFF: u1 = 0,
/// DOUBLE_BUFFERED [30:30]
/// This endpoint is double buffered.
DOUBLE_BUFFERED: u1 = 0,
/// ENABLE [31:31]
/// Enable this endpoint. The device will not reply to any packets for this endpoint if this bit is not set.
ENABLE: u1 = 0,
};
/// No description
pub const EP14_OUT_CONTROL = Register(EP14_OUT_CONTROL_val).init(base_address + 0x74);

/// EP14_IN_CONTROL
const EP14_IN_CONTROL_val = packed struct {
/// BUFFER_ADDRESS [0:15]
/// 64 byte aligned buffer address for this EP (bits 0-5 are ignored). Relative to the start of the DPRAM.
BUFFER_ADDRESS: u16 = 0,
/// INTERRUPT_ON_NAK [16:16]
/// Trigger an interrupt if a NAK is sent. Intended for debug only.
INTERRUPT_ON_NAK: u1 = 0,
/// INTERRUPT_ON_STALL [17:17]
/// Trigger an interrupt if a STALL is sent. Intended for debug only.
INTERRUPT_ON_STALL: u1 = 0,
/// unused [18:25]
_unused18: u6 = 0,
_unused24: u2 = 0,
/// ENDPOINT_TYPE [26:27]
/// No description
ENDPOINT_TYPE: u2 = 0,
/// INTERRUPT_PER_DOUBLE_BUFF [28:28]
/// Trigger an interrupt each time both buffers are done. Only valid in double buffered mode.
INTERRUPT_PER_DOUBLE_BUFF: u1 = 0,
/// INTERRUPT_PER_BUFF [29:29]
/// Trigger an interrupt each time a buffer is done.
INTERRUPT_PER_BUFF: u1 = 0,
/// DOUBLE_BUFFERED [30:30]
/// This endpoint is double buffered.
DOUBLE_BUFFERED: u1 = 0,
/// ENABLE [31:31]
/// Enable this endpoint. The device will not reply to any packets for this endpoint if this bit is not set.
ENABLE: u1 = 0,
};
/// No description
pub const EP14_IN_CONTROL = Register(EP14_IN_CONTROL_val).init(base_address + 0x70);

/// EP13_OUT_CONTROL
const EP13_OUT_CONTROL_val = packed struct {
/// BUFFER_ADDRESS [0:15]
/// 64 byte aligned buffer address for this EP (bits 0-5 are ignored). Relative to the start of the DPRAM.
BUFFER_ADDRESS: u16 = 0,
/// INTERRUPT_ON_NAK [16:16]
/// Trigger an interrupt if a NAK is sent. Intended for debug only.
INTERRUPT_ON_NAK: u1 = 0,
/// INTERRUPT_ON_STALL [17:17]
/// Trigger an interrupt if a STALL is sent. Intended for debug only.
INTERRUPT_ON_STALL: u1 = 0,
/// unused [18:25]
_unused18: u6 = 0,
_unused24: u2 = 0,
/// ENDPOINT_TYPE [26:27]
/// No description
ENDPOINT_TYPE: u2 = 0,
/// INTERRUPT_PER_DOUBLE_BUFF [28:28]
/// Trigger an interrupt each time both buffers are done. Only valid in double buffered mode.
INTERRUPT_PER_DOUBLE_BUFF: u1 = 0,
/// INTERRUPT_PER_BUFF [29:29]
/// Trigger an interrupt each time a buffer is done.
INTERRUPT_PER_BUFF: u1 = 0,
/// DOUBLE_BUFFERED [30:30]
/// This endpoint is double buffered.
DOUBLE_BUFFERED: u1 = 0,
/// ENABLE [31:31]
/// Enable this endpoint. The device will not reply to any packets for this endpoint if this bit is not set.
ENABLE: u1 = 0,
};
/// No description
pub const EP13_OUT_CONTROL = Register(EP13_OUT_CONTROL_val).init(base_address + 0x6c);

/// EP13_IN_CONTROL
const EP13_IN_CONTROL_val = packed struct {
/// BUFFER_ADDRESS [0:15]
/// 64 byte aligned buffer address for this EP (bits 0-5 are ignored). Relative to the start of the DPRAM.
BUFFER_ADDRESS: u16 = 0,
/// INTERRUPT_ON_NAK [16:16]
/// Trigger an interrupt if a NAK is sent. Intended for debug only.
INTERRUPT_ON_NAK: u1 = 0,
/// INTERRUPT_ON_STALL [17:17]
/// Trigger an interrupt if a STALL is sent. Intended for debug only.
INTERRUPT_ON_STALL: u1 = 0,
/// unused [18:25]
_unused18: u6 = 0,
_unused24: u2 = 0,
/// ENDPOINT_TYPE [26:27]
/// No description
ENDPOINT_TYPE: u2 = 0,
/// INTERRUPT_PER_DOUBLE_BUFF [28:28]
/// Trigger an interrupt each time both buffers are done. Only valid in double buffered mode.
INTERRUPT_PER_DOUBLE_BUFF: u1 = 0,
/// INTERRUPT_PER_BUFF [29:29]
/// Trigger an interrupt each time a buffer is done.
INTERRUPT_PER_BUFF: u1 = 0,
/// DOUBLE_BUFFERED [30:30]
/// This endpoint is double buffered.
DOUBLE_BUFFERED: u1 = 0,
/// ENABLE [31:31]
/// Enable this endpoint. The device will not reply to any packets for this endpoint if this bit is not set.
ENABLE: u1 = 0,
};
/// No description
pub const EP13_IN_CONTROL = Register(EP13_IN_CONTROL_val).init(base_address + 0x68);

/// EP12_OUT_CONTROL
const EP12_OUT_CONTROL_val = packed struct {
/// BUFFER_ADDRESS [0:15]
/// 64 byte aligned buffer address for this EP (bits 0-5 are ignored). Relative to the start of the DPRAM.
BUFFER_ADDRESS: u16 = 0,
/// INTERRUPT_ON_NAK [16:16]
/// Trigger an interrupt if a NAK is sent. Intended for debug only.
INTERRUPT_ON_NAK: u1 = 0,
/// INTERRUPT_ON_STALL [17:17]
/// Trigger an interrupt if a STALL is sent. Intended for debug only.
INTERRUPT_ON_STALL: u1 = 0,
/// unused [18:25]
_unused18: u6 = 0,
_unused24: u2 = 0,
/// ENDPOINT_TYPE [26:27]
/// No description
ENDPOINT_TYPE: u2 = 0,
/// INTERRUPT_PER_DOUBLE_BUFF [28:28]
/// Trigger an interrupt each time both buffers are done. Only valid in double buffered mode.
INTERRUPT_PER_DOUBLE_BUFF: u1 = 0,
/// INTERRUPT_PER_BUFF [29:29]
/// Trigger an interrupt each time a buffer is done.
INTERRUPT_PER_BUFF: u1 = 0,
/// DOUBLE_BUFFERED [30:30]
/// This endpoint is double buffered.
DOUBLE_BUFFERED: u1 = 0,
/// ENABLE [31:31]
/// Enable this endpoint. The device will not reply to any packets for this endpoint if this bit is not set.
ENABLE: u1 = 0,
};
/// No description
pub const EP12_OUT_CONTROL = Register(EP12_OUT_CONTROL_val).init(base_address + 0x64);

/// EP12_IN_CONTROL
const EP12_IN_CONTROL_val = packed struct {
/// BUFFER_ADDRESS [0:15]
/// 64 byte aligned buffer address for this EP (bits 0-5 are ignored). Relative to the start of the DPRAM.
BUFFER_ADDRESS: u16 = 0,
/// INTERRUPT_ON_NAK [16:16]
/// Trigger an interrupt if a NAK is sent. Intended for debug only.
INTERRUPT_ON_NAK: u1 = 0,
/// INTERRUPT_ON_STALL [17:17]
/// Trigger an interrupt if a STALL is sent. Intended for debug only.
INTERRUPT_ON_STALL: u1 = 0,
/// unused [18:25]
_unused18: u6 = 0,
_unused24: u2 = 0,
/// ENDPOINT_TYPE [26:27]
/// No description
ENDPOINT_TYPE: u2 = 0,
/// INTERRUPT_PER_DOUBLE_BUFF [28:28]
/// Trigger an interrupt each time both buffers are done. Only valid in double buffered mode.
INTERRUPT_PER_DOUBLE_BUFF: u1 = 0,
/// INTERRUPT_PER_BUFF [29:29]
/// Trigger an interrupt each time a buffer is done.
INTERRUPT_PER_BUFF: u1 = 0,
/// DOUBLE_BUFFERED [30:30]
/// This endpoint is double buffered.
DOUBLE_BUFFERED: u1 = 0,
/// ENABLE [31:31]
/// Enable this endpoint. The device will not reply to any packets for this endpoint if this bit is not set.
ENABLE: u1 = 0,
};
/// No description
pub const EP12_IN_CONTROL = Register(EP12_IN_CONTROL_val).init(base_address + 0x60);

/// EP11_OUT_CONTROL
const EP11_OUT_CONTROL_val = packed struct {
/// BUFFER_ADDRESS [0:15]
/// 64 byte aligned buffer address for this EP (bits 0-5 are ignored). Relative to the start of the DPRAM.
BUFFER_ADDRESS: u16 = 0,
/// INTERRUPT_ON_NAK [16:16]
/// Trigger an interrupt if a NAK is sent. Intended for debug only.
INTERRUPT_ON_NAK: u1 = 0,
/// INTERRUPT_ON_STALL [17:17]
/// Trigger an interrupt if a STALL is sent. Intended for debug only.
INTERRUPT_ON_STALL: u1 = 0,
/// unused [18:25]
_unused18: u6 = 0,
_unused24: u2 = 0,
/// ENDPOINT_TYPE [26:27]
/// No description
ENDPOINT_TYPE: u2 = 0,
/// INTERRUPT_PER_DOUBLE_BUFF [28:28]
/// Trigger an interrupt each time both buffers are done. Only valid in double buffered mode.
INTERRUPT_PER_DOUBLE_BUFF: u1 = 0,
/// INTERRUPT_PER_BUFF [29:29]
/// Trigger an interrupt each time a buffer is done.
INTERRUPT_PER_BUFF: u1 = 0,
/// DOUBLE_BUFFERED [30:30]
/// This endpoint is double buffered.
DOUBLE_BUFFERED: u1 = 0,
/// ENABLE [31:31]
/// Enable this endpoint. The device will not reply to any packets for this endpoint if this bit is not set.
ENABLE: u1 = 0,
};
/// No description
pub const EP11_OUT_CONTROL = Register(EP11_OUT_CONTROL_val).init(base_address + 0x5c);

/// EP11_IN_CONTROL
const EP11_IN_CONTROL_val = packed struct {
/// BUFFER_ADDRESS [0:15]
/// 64 byte aligned buffer address for this EP (bits 0-5 are ignored). Relative to the start of the DPRAM.
BUFFER_ADDRESS: u16 = 0,
/// INTERRUPT_ON_NAK [16:16]
/// Trigger an interrupt if a NAK is sent. Intended for debug only.
INTERRUPT_ON_NAK: u1 = 0,
/// INTERRUPT_ON_STALL [17:17]
/// Trigger an interrupt if a STALL is sent. Intended for debug only.
INTERRUPT_ON_STALL: u1 = 0,
/// unused [18:25]
_unused18: u6 = 0,
_unused24: u2 = 0,
/// ENDPOINT_TYPE [26:27]
/// No description
ENDPOINT_TYPE: u2 = 0,
/// INTERRUPT_PER_DOUBLE_BUFF [28:28]
/// Trigger an interrupt each time both buffers are done. Only valid in double buffered mode.
INTERRUPT_PER_DOUBLE_BUFF: u1 = 0,
/// INTERRUPT_PER_BUFF [29:29]
/// Trigger an interrupt each time a buffer is done.
INTERRUPT_PER_BUFF: u1 = 0,
/// DOUBLE_BUFFERED [30:30]
/// This endpoint is double buffered.
DOUBLE_BUFFERED: u1 = 0,
/// ENABLE [31:31]
/// Enable this endpoint. The device will not reply to any packets for this endpoint if this bit is not set.
ENABLE: u1 = 0,
};
/// No description
pub const EP11_IN_CONTROL = Register(EP11_IN_CONTROL_val).init(base_address + 0x58);

/// EP10_OUT_CONTROL
const EP10_OUT_CONTROL_val = packed struct {
/// BUFFER_ADDRESS [0:15]
/// 64 byte aligned buffer address for this EP (bits 0-5 are ignored). Relative to the start of the DPRAM.
BUFFER_ADDRESS: u16 = 0,
/// INTERRUPT_ON_NAK [16:16]
/// Trigger an interrupt if a NAK is sent. Intended for debug only.
INTERRUPT_ON_NAK: u1 = 0,
/// INTERRUPT_ON_STALL [17:17]
/// Trigger an interrupt if a STALL is sent. Intended for debug only.
INTERRUPT_ON_STALL: u1 = 0,
/// unused [18:25]
_unused18: u6 = 0,
_unused24: u2 = 0,
/// ENDPOINT_TYPE [26:27]
/// No description
ENDPOINT_TYPE: u2 = 0,
/// INTERRUPT_PER_DOUBLE_BUFF [28:28]
/// Trigger an interrupt each time both buffers are done. Only valid in double buffered mode.
INTERRUPT_PER_DOUBLE_BUFF: u1 = 0,
/// INTERRUPT_PER_BUFF [29:29]
/// Trigger an interrupt each time a buffer is done.
INTERRUPT_PER_BUFF: u1 = 0,
/// DOUBLE_BUFFERED [30:30]
/// This endpoint is double buffered.
DOUBLE_BUFFERED: u1 = 0,
/// ENABLE [31:31]
/// Enable this endpoint. The device will not reply to any packets for this endpoint if this bit is not set.
ENABLE: u1 = 0,
};
/// No description
pub const EP10_OUT_CONTROL = Register(EP10_OUT_CONTROL_val).init(base_address + 0x54);

/// EP10_IN_CONTROL
const EP10_IN_CONTROL_val = packed struct {
/// BUFFER_ADDRESS [0:15]
/// 64 byte aligned buffer address for this EP (bits 0-5 are ignored). Relative to the start of the DPRAM.
BUFFER_ADDRESS: u16 = 0,
/// INTERRUPT_ON_NAK [16:16]
/// Trigger an interrupt if a NAK is sent. Intended for debug only.
INTERRUPT_ON_NAK: u1 = 0,
/// INTERRUPT_ON_STALL [17:17]
/// Trigger an interrupt if a STALL is sent. Intended for debug only.
INTERRUPT_ON_STALL: u1 = 0,
/// unused [18:25]
_unused18: u6 = 0,
_unused24: u2 = 0,
/// ENDPOINT_TYPE [26:27]
/// No description
ENDPOINT_TYPE: u2 = 0,
/// INTERRUPT_PER_DOUBLE_BUFF [28:28]
/// Trigger an interrupt each time both buffers are done. Only valid in double buffered mode.
INTERRUPT_PER_DOUBLE_BUFF: u1 = 0,
/// INTERRUPT_PER_BUFF [29:29]
/// Trigger an interrupt each time a buffer is done.
INTERRUPT_PER_BUFF: u1 = 0,
/// DOUBLE_BUFFERED [30:30]
/// This endpoint is double buffered.
DOUBLE_BUFFERED: u1 = 0,
/// ENABLE [31:31]
/// Enable this endpoint. The device will not reply to any packets for this endpoint if this bit is not set.
ENABLE: u1 = 0,
};
/// No description
pub const EP10_IN_CONTROL = Register(EP10_IN_CONTROL_val).init(base_address + 0x50);

/// EP9_OUT_CONTROL
const EP9_OUT_CONTROL_val = packed struct {
/// BUFFER_ADDRESS [0:15]
/// 64 byte aligned buffer address for this EP (bits 0-5 are ignored). Relative to the start of the DPRAM.
BUFFER_ADDRESS: u16 = 0,
/// INTERRUPT_ON_NAK [16:16]
/// Trigger an interrupt if a NAK is sent. Intended for debug only.
INTERRUPT_ON_NAK: u1 = 0,
/// INTERRUPT_ON_STALL [17:17]
/// Trigger an interrupt if a STALL is sent. Intended for debug only.
INTERRUPT_ON_STALL: u1 = 0,
/// unused [18:25]
_unused18: u6 = 0,
_unused24: u2 = 0,
/// ENDPOINT_TYPE [26:27]
/// No description
ENDPOINT_TYPE: u2 = 0,
/// INTERRUPT_PER_DOUBLE_BUFF [28:28]
/// Trigger an interrupt each time both buffers are done. Only valid in double buffered mode.
INTERRUPT_PER_DOUBLE_BUFF: u1 = 0,
/// INTERRUPT_PER_BUFF [29:29]
/// Trigger an interrupt each time a buffer is done.
INTERRUPT_PER_BUFF: u1 = 0,
/// DOUBLE_BUFFERED [30:30]
/// This endpoint is double buffered.
DOUBLE_BUFFERED: u1 = 0,
/// ENABLE [31:31]
/// Enable this endpoint. The device will not reply to any packets for this endpoint if this bit is not set.
ENABLE: u1 = 0,
};
/// No description
pub const EP9_OUT_CONTROL = Register(EP9_OUT_CONTROL_val).init(base_address + 0x4c);

/// EP9_IN_CONTROL
const EP9_IN_CONTROL_val = packed struct {
/// BUFFER_ADDRESS [0:15]
/// 64 byte aligned buffer address for this EP (bits 0-5 are ignored). Relative to the start of the DPRAM.
BUFFER_ADDRESS: u16 = 0,
/// INTERRUPT_ON_NAK [16:16]
/// Trigger an interrupt if a NAK is sent. Intended for debug only.
INTERRUPT_ON_NAK: u1 = 0,
/// INTERRUPT_ON_STALL [17:17]
/// Trigger an interrupt if a STALL is sent. Intended for debug only.
INTERRUPT_ON_STALL: u1 = 0,
/// unused [18:25]
_unused18: u6 = 0,
_unused24: u2 = 0,
/// ENDPOINT_TYPE [26:27]
/// No description
ENDPOINT_TYPE: u2 = 0,
/// INTERRUPT_PER_DOUBLE_BUFF [28:28]
/// Trigger an interrupt each time both buffers are done. Only valid in double buffered mode.
INTERRUPT_PER_DOUBLE_BUFF: u1 = 0,
/// INTERRUPT_PER_BUFF [29:29]
/// Trigger an interrupt each time a buffer is done.
INTERRUPT_PER_BUFF: u1 = 0,
/// DOUBLE_BUFFERED [30:30]
/// This endpoint is double buffered.
DOUBLE_BUFFERED: u1 = 0,
/// ENABLE [31:31]
/// Enable this endpoint. The device will not reply to any packets for this endpoint if this bit is not set.
ENABLE: u1 = 0,
};
/// No description
pub const EP9_IN_CONTROL = Register(EP9_IN_CONTROL_val).init(base_address + 0x48);

/// EP8_OUT_CONTROL
const EP8_OUT_CONTROL_val = packed struct {
/// BUFFER_ADDRESS [0:15]
/// 64 byte aligned buffer address for this EP (bits 0-5 are ignored). Relative to the start of the DPRAM.
BUFFER_ADDRESS: u16 = 0,
/// INTERRUPT_ON_NAK [16:16]
/// Trigger an interrupt if a NAK is sent. Intended for debug only.
INTERRUPT_ON_NAK: u1 = 0,
/// INTERRUPT_ON_STALL [17:17]
/// Trigger an interrupt if a STALL is sent. Intended for debug only.
INTERRUPT_ON_STALL: u1 = 0,
/// unused [18:25]
_unused18: u6 = 0,
_unused24: u2 = 0,
/// ENDPOINT_TYPE [26:27]
/// No description
ENDPOINT_TYPE: u2 = 0,
/// INTERRUPT_PER_DOUBLE_BUFF [28:28]
/// Trigger an interrupt each time both buffers are done. Only valid in double buffered mode.
INTERRUPT_PER_DOUBLE_BUFF: u1 = 0,
/// INTERRUPT_PER_BUFF [29:29]
/// Trigger an interrupt each time a buffer is done.
INTERRUPT_PER_BUFF: u1 = 0,
/// DOUBLE_BUFFERED [30:30]
/// This endpoint is double buffered.
DOUBLE_BUFFERED: u1 = 0,
/// ENABLE [31:31]
/// Enable this endpoint. The device will not reply to any packets for this endpoint if this bit is not set.
ENABLE: u1 = 0,
};
/// No description
pub const EP8_OUT_CONTROL = Register(EP8_OUT_CONTROL_val).init(base_address + 0x44);

/// EP8_IN_CONTROL
const EP8_IN_CONTROL_val = packed struct {
/// BUFFER_ADDRESS [0:15]
/// 64 byte aligned buffer address for this EP (bits 0-5 are ignored). Relative to the start of the DPRAM.
BUFFER_ADDRESS: u16 = 0,
/// INTERRUPT_ON_NAK [16:16]
/// Trigger an interrupt if a NAK is sent. Intended for debug only.
INTERRUPT_ON_NAK: u1 = 0,
/// INTERRUPT_ON_STALL [17:17]
/// Trigger an interrupt if a STALL is sent. Intended for debug only.
INTERRUPT_ON_STALL: u1 = 0,
/// unused [18:25]
_unused18: u6 = 0,
_unused24: u2 = 0,
/// ENDPOINT_TYPE [26:27]
/// No description
ENDPOINT_TYPE: u2 = 0,
/// INTERRUPT_PER_DOUBLE_BUFF [28:28]
/// Trigger an interrupt each time both buffers are done. Only valid in double buffered mode.
INTERRUPT_PER_DOUBLE_BUFF: u1 = 0,
/// INTERRUPT_PER_BUFF [29:29]
/// Trigger an interrupt each time a buffer is done.
INTERRUPT_PER_BUFF: u1 = 0,
/// DOUBLE_BUFFERED [30:30]
/// This endpoint is double buffered.
DOUBLE_BUFFERED: u1 = 0,
/// ENABLE [31:31]
/// Enable this endpoint. The device will not reply to any packets for this endpoint if this bit is not set.
ENABLE: u1 = 0,
};
/// No description
pub const EP8_IN_CONTROL = Register(EP8_IN_CONTROL_val).init(base_address + 0x40);

/// EP7_OUT_CONTROL
const EP7_OUT_CONTROL_val = packed struct {
/// BUFFER_ADDRESS [0:15]
/// 64 byte aligned buffer address for this EP (bits 0-5 are ignored). Relative to the start of the DPRAM.
BUFFER_ADDRESS: u16 = 0,
/// INTERRUPT_ON_NAK [16:16]
/// Trigger an interrupt if a NAK is sent. Intended for debug only.
INTERRUPT_ON_NAK: u1 = 0,
/// INTERRUPT_ON_STALL [17:17]
/// Trigger an interrupt if a STALL is sent. Intended for debug only.
INTERRUPT_ON_STALL: u1 = 0,
/// unused [18:25]
_unused18: u6 = 0,
_unused24: u2 = 0,
/// ENDPOINT_TYPE [26:27]
/// No description
ENDPOINT_TYPE: u2 = 0,
/// INTERRUPT_PER_DOUBLE_BUFF [28:28]
/// Trigger an interrupt each time both buffers are done. Only valid in double buffered mode.
INTERRUPT_PER_DOUBLE_BUFF: u1 = 0,
/// INTERRUPT_PER_BUFF [29:29]
/// Trigger an interrupt each time a buffer is done.
INTERRUPT_PER_BUFF: u1 = 0,
/// DOUBLE_BUFFERED [30:30]
/// This endpoint is double buffered.
DOUBLE_BUFFERED: u1 = 0,
/// ENABLE [31:31]
/// Enable this endpoint. The device will not reply to any packets for this endpoint if this bit is not set.
ENABLE: u1 = 0,
};
/// No description
pub const EP7_OUT_CONTROL = Register(EP7_OUT_CONTROL_val).init(base_address + 0x3c);

/// EP7_IN_CONTROL
const EP7_IN_CONTROL_val = packed struct {
/// BUFFER_ADDRESS [0:15]
/// 64 byte aligned buffer address for this EP (bits 0-5 are ignored). Relative to the start of the DPRAM.
BUFFER_ADDRESS: u16 = 0,
/// INTERRUPT_ON_NAK [16:16]
/// Trigger an interrupt if a NAK is sent. Intended for debug only.
INTERRUPT_ON_NAK: u1 = 0,
/// INTERRUPT_ON_STALL [17:17]
/// Trigger an interrupt if a STALL is sent. Intended for debug only.
INTERRUPT_ON_STALL: u1 = 0,
/// unused [18:25]
_unused18: u6 = 0,
_unused24: u2 = 0,
/// ENDPOINT_TYPE [26:27]
/// No description
ENDPOINT_TYPE: u2 = 0,
/// INTERRUPT_PER_DOUBLE_BUFF [28:28]
/// Trigger an interrupt each time both buffers are done. Only valid in double buffered mode.
INTERRUPT_PER_DOUBLE_BUFF: u1 = 0,
/// INTERRUPT_PER_BUFF [29:29]
/// Trigger an interrupt each time a buffer is done.
INTERRUPT_PER_BUFF: u1 = 0,
/// DOUBLE_BUFFERED [30:30]
/// This endpoint is double buffered.
DOUBLE_BUFFERED: u1 = 0,
/// ENABLE [31:31]
/// Enable this endpoint. The device will not reply to any packets for this endpoint if this bit is not set.
ENABLE: u1 = 0,
};
/// No description
pub const EP7_IN_CONTROL = Register(EP7_IN_CONTROL_val).init(base_address + 0x38);

/// EP6_OUT_CONTROL
const EP6_OUT_CONTROL_val = packed struct {
/// BUFFER_ADDRESS [0:15]
/// 64 byte aligned buffer address for this EP (bits 0-5 are ignored). Relative to the start of the DPRAM.
BUFFER_ADDRESS: u16 = 0,
/// INTERRUPT_ON_NAK [16:16]
/// Trigger an interrupt if a NAK is sent. Intended for debug only.
INTERRUPT_ON_NAK: u1 = 0,
/// INTERRUPT_ON_STALL [17:17]
/// Trigger an interrupt if a STALL is sent. Intended for debug only.
INTERRUPT_ON_STALL: u1 = 0,
/// unused [18:25]
_unused18: u6 = 0,
_unused24: u2 = 0,
/// ENDPOINT_TYPE [26:27]
/// No description
ENDPOINT_TYPE: u2 = 0,
/// INTERRUPT_PER_DOUBLE_BUFF [28:28]
/// Trigger an interrupt each time both buffers are done. Only valid in double buffered mode.
INTERRUPT_PER_DOUBLE_BUFF: u1 = 0,
/// INTERRUPT_PER_BUFF [29:29]
/// Trigger an interrupt each time a buffer is done.
INTERRUPT_PER_BUFF: u1 = 0,
/// DOUBLE_BUFFERED [30:30]
/// This endpoint is double buffered.
DOUBLE_BUFFERED: u1 = 0,
/// ENABLE [31:31]
/// Enable this endpoint. The device will not reply to any packets for this endpoint if this bit is not set.
ENABLE: u1 = 0,
};
/// No description
pub const EP6_OUT_CONTROL = Register(EP6_OUT_CONTROL_val).init(base_address + 0x34);

/// EP6_IN_CONTROL
const EP6_IN_CONTROL_val = packed struct {
/// BUFFER_ADDRESS [0:15]
/// 64 byte aligned buffer address for this EP (bits 0-5 are ignored). Relative to the start of the DPRAM.
BUFFER_ADDRESS: u16 = 0,
/// INTERRUPT_ON_NAK [16:16]
/// Trigger an interrupt if a NAK is sent. Intended for debug only.
INTERRUPT_ON_NAK: u1 = 0,
/// INTERRUPT_ON_STALL [17:17]
/// Trigger an interrupt if a STALL is sent. Intended for debug only.
INTERRUPT_ON_STALL: u1 = 0,
/// unused [18:25]
_unused18: u6 = 0,
_unused24: u2 = 0,
/// ENDPOINT_TYPE [26:27]
/// No description
ENDPOINT_TYPE: u2 = 0,
/// INTERRUPT_PER_DOUBLE_BUFF [28:28]
/// Trigger an interrupt each time both buffers are done. Only valid in double buffered mode.
INTERRUPT_PER_DOUBLE_BUFF: u1 = 0,
/// INTERRUPT_PER_BUFF [29:29]
/// Trigger an interrupt each time a buffer is done.
INTERRUPT_PER_BUFF: u1 = 0,
/// DOUBLE_BUFFERED [30:30]
/// This endpoint is double buffered.
DOUBLE_BUFFERED: u1 = 0,
/// ENABLE [31:31]
/// Enable this endpoint. The device will not reply to any packets for this endpoint if this bit is not set.
ENABLE: u1 = 0,
};
/// No description
pub const EP6_IN_CONTROL = Register(EP6_IN_CONTROL_val).init(base_address + 0x30);

/// EP5_OUT_CONTROL
const EP5_OUT_CONTROL_val = packed struct {
/// BUFFER_ADDRESS [0:15]
/// 64 byte aligned buffer address for this EP (bits 0-5 are ignored). Relative to the start of the DPRAM.
BUFFER_ADDRESS: u16 = 0,
/// INTERRUPT_ON_NAK [16:16]
/// Trigger an interrupt if a NAK is sent. Intended for debug only.
INTERRUPT_ON_NAK: u1 = 0,
/// INTERRUPT_ON_STALL [17:17]
/// Trigger an interrupt if a STALL is sent. Intended for debug only.
INTERRUPT_ON_STALL: u1 = 0,
/// unused [18:25]
_unused18: u6 = 0,
_unused24: u2 = 0,
/// ENDPOINT_TYPE [26:27]
/// No description
ENDPOINT_TYPE: u2 = 0,
/// INTERRUPT_PER_DOUBLE_BUFF [28:28]
/// Trigger an interrupt each time both buffers are done. Only valid in double buffered mode.
INTERRUPT_PER_DOUBLE_BUFF: u1 = 0,
/// INTERRUPT_PER_BUFF [29:29]
/// Trigger an interrupt each time a buffer is done.
INTERRUPT_PER_BUFF: u1 = 0,
/// DOUBLE_BUFFERED [30:30]
/// This endpoint is double buffered.
DOUBLE_BUFFERED: u1 = 0,
/// ENABLE [31:31]
/// Enable this endpoint. The device will not reply to any packets for this endpoint if this bit is not set.
ENABLE: u1 = 0,
};
/// No description
pub const EP5_OUT_CONTROL = Register(EP5_OUT_CONTROL_val).init(base_address + 0x2c);

/// EP5_IN_CONTROL
const EP5_IN_CONTROL_val = packed struct {
/// BUFFER_ADDRESS [0:15]
/// 64 byte aligned buffer address for this EP (bits 0-5 are ignored). Relative to the start of the DPRAM.
BUFFER_ADDRESS: u16 = 0,
/// INTERRUPT_ON_NAK [16:16]
/// Trigger an interrupt if a NAK is sent. Intended for debug only.
INTERRUPT_ON_NAK: u1 = 0,
/// INTERRUPT_ON_STALL [17:17]
/// Trigger an interrupt if a STALL is sent. Intended for debug only.
INTERRUPT_ON_STALL: u1 = 0,
/// unused [18:25]
_unused18: u6 = 0,
_unused24: u2 = 0,
/// ENDPOINT_TYPE [26:27]
/// No description
ENDPOINT_TYPE: u2 = 0,
/// INTERRUPT_PER_DOUBLE_BUFF [28:28]
/// Trigger an interrupt each time both buffers are done. Only valid in double buffered mode.
INTERRUPT_PER_DOUBLE_BUFF: u1 = 0,
/// INTERRUPT_PER_BUFF [29:29]
/// Trigger an interrupt each time a buffer is done.
INTERRUPT_PER_BUFF: u1 = 0,
/// DOUBLE_BUFFERED [30:30]
/// This endpoint is double buffered.
DOUBLE_BUFFERED: u1 = 0,
/// ENABLE [31:31]
/// Enable this endpoint. The device will not reply to any packets for this endpoint if this bit is not set.
ENABLE: u1 = 0,
};
/// No description
pub const EP5_IN_CONTROL = Register(EP5_IN_CONTROL_val).init(base_address + 0x28);

/// EP4_OUT_CONTROL
const EP4_OUT_CONTROL_val = packed struct {
/// BUFFER_ADDRESS [0:15]
/// 64 byte aligned buffer address for this EP (bits 0-5 are ignored). Relative to the start of the DPRAM.
BUFFER_ADDRESS: u16 = 0,
/// INTERRUPT_ON_NAK [16:16]
/// Trigger an interrupt if a NAK is sent. Intended for debug only.
INTERRUPT_ON_NAK: u1 = 0,
/// INTERRUPT_ON_STALL [17:17]
/// Trigger an interrupt if a STALL is sent. Intended for debug only.
INTERRUPT_ON_STALL: u1 = 0,
/// unused [18:25]
_unused18: u6 = 0,
_unused24: u2 = 0,
/// ENDPOINT_TYPE [26:27]
/// No description
ENDPOINT_TYPE: u2 = 0,
/// INTERRUPT_PER_DOUBLE_BUFF [28:28]
/// Trigger an interrupt each time both buffers are done. Only valid in double buffered mode.
INTERRUPT_PER_DOUBLE_BUFF: u1 = 0,
/// INTERRUPT_PER_BUFF [29:29]
/// Trigger an interrupt each time a buffer is done.
INTERRUPT_PER_BUFF: u1 = 0,
/// DOUBLE_BUFFERED [30:30]
/// This endpoint is double buffered.
DOUBLE_BUFFERED: u1 = 0,
/// ENABLE [31:31]
/// Enable this endpoint. The device will not reply to any packets for this endpoint if this bit is not set.
ENABLE: u1 = 0,
};
/// No description
pub const EP4_OUT_CONTROL = Register(EP4_OUT_CONTROL_val).init(base_address + 0x24);

/// EP4_IN_CONTROL
const EP4_IN_CONTROL_val = packed struct {
/// BUFFER_ADDRESS [0:15]
/// 64 byte aligned buffer address for this EP (bits 0-5 are ignored). Relative to the start of the DPRAM.
BUFFER_ADDRESS: u16 = 0,
/// INTERRUPT_ON_NAK [16:16]
/// Trigger an interrupt if a NAK is sent. Intended for debug only.
INTERRUPT_ON_NAK: u1 = 0,
/// INTERRUPT_ON_STALL [17:17]
/// Trigger an interrupt if a STALL is sent. Intended for debug only.
INTERRUPT_ON_STALL: u1 = 0,
/// unused [18:25]
_unused18: u6 = 0,
_unused24: u2 = 0,
/// ENDPOINT_TYPE [26:27]
/// No description
ENDPOINT_TYPE: u2 = 0,
/// INTERRUPT_PER_DOUBLE_BUFF [28:28]
/// Trigger an interrupt each time both buffers are done. Only valid in double buffered mode.
INTERRUPT_PER_DOUBLE_BUFF: u1 = 0,
/// INTERRUPT_PER_BUFF [29:29]
/// Trigger an interrupt each time a buffer is done.
INTERRUPT_PER_BUFF: u1 = 0,
/// DOUBLE_BUFFERED [30:30]
/// This endpoint is double buffered.
DOUBLE_BUFFERED: u1 = 0,
/// ENABLE [31:31]
/// Enable this endpoint. The device will not reply to any packets for this endpoint if this bit is not set.
ENABLE: u1 = 0,
};
/// No description
pub const EP4_IN_CONTROL = Register(EP4_IN_CONTROL_val).init(base_address + 0x20);

/// EP3_OUT_CONTROL
const EP3_OUT_CONTROL_val = packed struct {
/// BUFFER_ADDRESS [0:15]
/// 64 byte aligned buffer address for this EP (bits 0-5 are ignored). Relative to the start of the DPRAM.
BUFFER_ADDRESS: u16 = 0,
/// INTERRUPT_ON_NAK [16:16]
/// Trigger an interrupt if a NAK is sent. Intended for debug only.
INTERRUPT_ON_NAK: u1 = 0,
/// INTERRUPT_ON_STALL [17:17]
/// Trigger an interrupt if a STALL is sent. Intended for debug only.
INTERRUPT_ON_STALL: u1 = 0,
/// unused [18:25]
_unused18: u6 = 0,
_unused24: u2 = 0,
/// ENDPOINT_TYPE [26:27]
/// No description
ENDPOINT_TYPE: u2 = 0,
/// INTERRUPT_PER_DOUBLE_BUFF [28:28]
/// Trigger an interrupt each time both buffers are done. Only valid in double buffered mode.
INTERRUPT_PER_DOUBLE_BUFF: u1 = 0,
/// INTERRUPT_PER_BUFF [29:29]
/// Trigger an interrupt each time a buffer is done.
INTERRUPT_PER_BUFF: u1 = 0,
/// DOUBLE_BUFFERED [30:30]
/// This endpoint is double buffered.
DOUBLE_BUFFERED: u1 = 0,
/// ENABLE [31:31]
/// Enable this endpoint. The device will not reply to any packets for this endpoint if this bit is not set.
ENABLE: u1 = 0,
};
/// No description
pub const EP3_OUT_CONTROL = Register(EP3_OUT_CONTROL_val).init(base_address + 0x1c);

/// EP3_IN_CONTROL
const EP3_IN_CONTROL_val = packed struct {
/// BUFFER_ADDRESS [0:15]
/// 64 byte aligned buffer address for this EP (bits 0-5 are ignored). Relative to the start of the DPRAM.
BUFFER_ADDRESS: u16 = 0,
/// INTERRUPT_ON_NAK [16:16]
/// Trigger an interrupt if a NAK is sent. Intended for debug only.
INTERRUPT_ON_NAK: u1 = 0,
/// INTERRUPT_ON_STALL [17:17]
/// Trigger an interrupt if a STALL is sent. Intended for debug only.
INTERRUPT_ON_STALL: u1 = 0,
/// unused [18:25]
_unused18: u6 = 0,
_unused24: u2 = 0,
/// ENDPOINT_TYPE [26:27]
/// No description
ENDPOINT_TYPE: u2 = 0,
/// INTERRUPT_PER_DOUBLE_BUFF [28:28]
/// Trigger an interrupt each time both buffers are done. Only valid in double buffered mode.
INTERRUPT_PER_DOUBLE_BUFF: u1 = 0,
/// INTERRUPT_PER_BUFF [29:29]
/// Trigger an interrupt each time a buffer is done.
INTERRUPT_PER_BUFF: u1 = 0,
/// DOUBLE_BUFFERED [30:30]
/// This endpoint is double buffered.
DOUBLE_BUFFERED: u1 = 0,
/// ENABLE [31:31]
/// Enable this endpoint. The device will not reply to any packets for this endpoint if this bit is not set.
ENABLE: u1 = 0,
};
/// No description
pub const EP3_IN_CONTROL = Register(EP3_IN_CONTROL_val).init(base_address + 0x18);

/// EP2_OUT_CONTROL
const EP2_OUT_CONTROL_val = packed struct {
/// BUFFER_ADDRESS [0:15]
/// 64 byte aligned buffer address for this EP (bits 0-5 are ignored). Relative to the start of the DPRAM.
BUFFER_ADDRESS: u16 = 0,
/// INTERRUPT_ON_NAK [16:16]
/// Trigger an interrupt if a NAK is sent. Intended for debug only.
INTERRUPT_ON_NAK: u1 = 0,
/// INTERRUPT_ON_STALL [17:17]
/// Trigger an interrupt if a STALL is sent. Intended for debug only.
INTERRUPT_ON_STALL: u1 = 0,
/// unused [18:25]
_unused18: u6 = 0,
_unused24: u2 = 0,
/// ENDPOINT_TYPE [26:27]
/// No description
ENDPOINT_TYPE: u2 = 0,
/// INTERRUPT_PER_DOUBLE_BUFF [28:28]
/// Trigger an interrupt each time both buffers are done. Only valid in double buffered mode.
INTERRUPT_PER_DOUBLE_BUFF: u1 = 0,
/// INTERRUPT_PER_BUFF [29:29]
/// Trigger an interrupt each time a buffer is done.
INTERRUPT_PER_BUFF: u1 = 0,
/// DOUBLE_BUFFERED [30:30]
/// This endpoint is double buffered.
DOUBLE_BUFFERED: u1 = 0,
/// ENABLE [31:31]
/// Enable this endpoint. The device will not reply to any packets for this endpoint if this bit is not set.
ENABLE: u1 = 0,
};
/// No description
pub const EP2_OUT_CONTROL = Register(EP2_OUT_CONTROL_val).init(base_address + 0x14);

/// EP2_IN_CONTROL
const EP2_IN_CONTROL_val = packed struct {
/// BUFFER_ADDRESS [0:15]
/// 64 byte aligned buffer address for this EP (bits 0-5 are ignored). Relative to the start of the DPRAM.
BUFFER_ADDRESS: u16 = 0,
/// INTERRUPT_ON_NAK [16:16]
/// Trigger an interrupt if a NAK is sent. Intended for debug only.
INTERRUPT_ON_NAK: u1 = 0,
/// INTERRUPT_ON_STALL [17:17]
/// Trigger an interrupt if a STALL is sent. Intended for debug only.
INTERRUPT_ON_STALL: u1 = 0,
/// unused [18:25]
_unused18: u6 = 0,
_unused24: u2 = 0,
/// ENDPOINT_TYPE [26:27]
/// No description
ENDPOINT_TYPE: u2 = 0,
/// INTERRUPT_PER_DOUBLE_BUFF [28:28]
/// Trigger an interrupt each time both buffers are done. Only valid in double buffered mode.
INTERRUPT_PER_DOUBLE_BUFF: u1 = 0,
/// INTERRUPT_PER_BUFF [29:29]
/// Trigger an interrupt each time a buffer is done.
INTERRUPT_PER_BUFF: u1 = 0,
/// DOUBLE_BUFFERED [30:30]
/// This endpoint is double buffered.
DOUBLE_BUFFERED: u1 = 0,
/// ENABLE [31:31]
/// Enable this endpoint. The device will not reply to any packets for this endpoint if this bit is not set.
ENABLE: u1 = 0,
};
/// No description
pub const EP2_IN_CONTROL = Register(EP2_IN_CONTROL_val).init(base_address + 0x10);

/// EP1_OUT_CONTROL
const EP1_OUT_CONTROL_val = packed struct {
/// BUFFER_ADDRESS [0:15]
/// 64 byte aligned buffer address for this EP (bits 0-5 are ignored). Relative to the start of the DPRAM.
BUFFER_ADDRESS: u16 = 0,
/// INTERRUPT_ON_NAK [16:16]
/// Trigger an interrupt if a NAK is sent. Intended for debug only.
INTERRUPT_ON_NAK: u1 = 0,
/// INTERRUPT_ON_STALL [17:17]
/// Trigger an interrupt if a STALL is sent. Intended for debug only.
INTERRUPT_ON_STALL: u1 = 0,
/// unused [18:25]
_unused18: u6 = 0,
_unused24: u2 = 0,
/// ENDPOINT_TYPE [26:27]
/// No description
ENDPOINT_TYPE: u2 = 0,
/// INTERRUPT_PER_DOUBLE_BUFF [28:28]
/// Trigger an interrupt each time both buffers are done. Only valid in double buffered mode.
INTERRUPT_PER_DOUBLE_BUFF: u1 = 0,
/// INTERRUPT_PER_BUFF [29:29]
/// Trigger an interrupt each time a buffer is done.
INTERRUPT_PER_BUFF: u1 = 0,
/// DOUBLE_BUFFERED [30:30]
/// This endpoint is double buffered.
DOUBLE_BUFFERED: u1 = 0,
/// ENABLE [31:31]
/// Enable this endpoint. The device will not reply to any packets for this endpoint if this bit is not set.
ENABLE: u1 = 0,
};
/// No description
pub const EP1_OUT_CONTROL = Register(EP1_OUT_CONTROL_val).init(base_address + 0xc);

/// EP1_IN_CONTROL
const EP1_IN_CONTROL_val = packed struct {
/// BUFFER_ADDRESS [0:15]
/// 64 byte aligned buffer address for this EP (bits 0-5 are ignored). Relative to the start of the DPRAM.
BUFFER_ADDRESS: u16 = 0,
/// INTERRUPT_ON_NAK [16:16]
/// Trigger an interrupt if a NAK is sent. Intended for debug only.
INTERRUPT_ON_NAK: u1 = 0,
/// INTERRUPT_ON_STALL [17:17]
/// Trigger an interrupt if a STALL is sent. Intended for debug only.
INTERRUPT_ON_STALL: u1 = 0,
/// unused [18:25]
_unused18: u6 = 0,
_unused24: u2 = 0,
/// ENDPOINT_TYPE [26:27]
/// No description
ENDPOINT_TYPE: u2 = 0,
/// INTERRUPT_PER_DOUBLE_BUFF [28:28]
/// Trigger an interrupt each time both buffers are done. Only valid in double buffered mode.
INTERRUPT_PER_DOUBLE_BUFF: u1 = 0,
/// INTERRUPT_PER_BUFF [29:29]
/// Trigger an interrupt each time a buffer is done.
INTERRUPT_PER_BUFF: u1 = 0,
/// DOUBLE_BUFFERED [30:30]
/// This endpoint is double buffered.
DOUBLE_BUFFERED: u1 = 0,
/// ENABLE [31:31]
/// Enable this endpoint. The device will not reply to any packets for this endpoint if this bit is not set.
ENABLE: u1 = 0,
};
/// No description
pub const EP1_IN_CONTROL = Register(EP1_IN_CONTROL_val).init(base_address + 0x8);

/// SETUP_PACKET_HIGH
const SETUP_PACKET_HIGH_val = packed struct {
/// WINDEX [0:15]
/// No description
WINDEX: u16 = 0,
/// WLENGTH [16:31]
/// No description
WLENGTH: u16 = 0,
};
/// Bytes 4-7 of the setup packet from the host.
pub const SETUP_PACKET_HIGH = Register(SETUP_PACKET_HIGH_val).init(base_address + 0x4);

/// SETUP_PACKET_LOW
const SETUP_PACKET_LOW_val = packed struct {
/// BMREQUESTTYPE [0:7]
/// No description
BMREQUESTTYPE: u8 = 0,
/// BREQUEST [8:15]
/// No description
BREQUEST: u8 = 0,
/// WVALUE [16:31]
/// No description
WVALUE: u16 = 0,
};
/// Bytes 0-3 of the SETUP packet from the host.
pub const SETUP_PACKET_LOW = Register(SETUP_PACKET_LOW_val).init(base_address + 0x0);
};

/// USB FS/LS controller device registers
pub const USBCTRL_REGS = struct {

const base_address = 0x50110000;
/// INTS
const INTS_val = packed struct {
/// HOST_CONN_DIS [0:0]
/// Host: raised when a device is connected or disconnected (i.e. when SIE_STATUS.SPEED changes). Cleared by writing to SIE_STATUS.SPEED
HOST_CONN_DIS: u1 = 0,
/// HOST_RESUME [1:1]
/// Host: raised when a device wakes up the host. Cleared by writing to SIE_STATUS.RESUME
HOST_RESUME: u1 = 0,
/// HOST_SOF [2:2]
/// Host: raised every time the host sends a SOF (Start of Frame). Cleared by reading SOF_RD
HOST_SOF: u1 = 0,
/// TRANS_COMPLETE [3:3]
/// Raised every time SIE_STATUS.TRANS_COMPLETE is set. Clear by writing to this bit.
TRANS_COMPLETE: u1 = 0,
/// BUFF_STATUS [4:4]
/// Raised when any bit in BUFF_STATUS is set. Clear by clearing all bits in BUFF_STATUS.
BUFF_STATUS: u1 = 0,
/// ERROR_DATA_SEQ [5:5]
/// Source: SIE_STATUS.DATA_SEQ_ERROR
ERROR_DATA_SEQ: u1 = 0,
/// ERROR_RX_TIMEOUT [6:6]
/// Source: SIE_STATUS.RX_TIMEOUT
ERROR_RX_TIMEOUT: u1 = 0,
/// ERROR_RX_OVERFLOW [7:7]
/// Source: SIE_STATUS.RX_OVERFLOW
ERROR_RX_OVERFLOW: u1 = 0,
/// ERROR_BIT_STUFF [8:8]
/// Source: SIE_STATUS.BIT_STUFF_ERROR
ERROR_BIT_STUFF: u1 = 0,
/// ERROR_CRC [9:9]
/// Source: SIE_STATUS.CRC_ERROR
ERROR_CRC: u1 = 0,
/// STALL [10:10]
/// Source: SIE_STATUS.STALL_REC
STALL: u1 = 0,
/// VBUS_DETECT [11:11]
/// Source: SIE_STATUS.VBUS_DETECT
VBUS_DETECT: u1 = 0,
/// BUS_RESET [12:12]
/// Source: SIE_STATUS.BUS_RESET
BUS_RESET: u1 = 0,
/// DEV_CONN_DIS [13:13]
/// Set when the device connection state changes. Cleared by writing to SIE_STATUS.CONNECTED
DEV_CONN_DIS: u1 = 0,
/// DEV_SUSPEND [14:14]
/// Set when the device suspend state changes. Cleared by writing to SIE_STATUS.SUSPENDED
DEV_SUSPEND: u1 = 0,
/// DEV_RESUME_FROM_HOST [15:15]
/// Set when the device receives a resume from the host. Cleared by writing to SIE_STATUS.RESUME
DEV_RESUME_FROM_HOST: u1 = 0,
/// SETUP_REQ [16:16]
/// Device. Source: SIE_STATUS.SETUP_REC
SETUP_REQ: u1 = 0,
/// DEV_SOF [17:17]
/// Set every time the device receives a SOF (Start of Frame) packet. Cleared by reading SOF_RD
DEV_SOF: u1 = 0,
/// ABORT_DONE [18:18]
/// Raised when any bit in ABORT_DONE is set. Clear by clearing all bits in ABORT_DONE.
ABORT_DONE: u1 = 0,
/// EP_STALL_NAK [19:19]
/// Raised when any bit in EP_STATUS_STALL_NAK is set. Clear by clearing all bits in EP_STATUS_STALL_NAK.
EP_STALL_NAK: u1 = 0,
/// unused [20:31]
_unused20: u4 = 0,
_unused24: u8 = 0,
};
/// Interrupt status after masking &amp; forcing
pub const INTS = Register(INTS_val).init(base_address + 0x98);

/// INTF
const INTF_val = packed struct {
/// HOST_CONN_DIS [0:0]
/// Host: raised when a device is connected or disconnected (i.e. when SIE_STATUS.SPEED changes). Cleared by writing to SIE_STATUS.SPEED
HOST_CONN_DIS: u1 = 0,
/// HOST_RESUME [1:1]
/// Host: raised when a device wakes up the host. Cleared by writing to SIE_STATUS.RESUME
HOST_RESUME: u1 = 0,
/// HOST_SOF [2:2]
/// Host: raised every time the host sends a SOF (Start of Frame). Cleared by reading SOF_RD
HOST_SOF: u1 = 0,
/// TRANS_COMPLETE [3:3]
/// Raised every time SIE_STATUS.TRANS_COMPLETE is set. Clear by writing to this bit.
TRANS_COMPLETE: u1 = 0,
/// BUFF_STATUS [4:4]
/// Raised when any bit in BUFF_STATUS is set. Clear by clearing all bits in BUFF_STATUS.
BUFF_STATUS: u1 = 0,
/// ERROR_DATA_SEQ [5:5]
/// Source: SIE_STATUS.DATA_SEQ_ERROR
ERROR_DATA_SEQ: u1 = 0,
/// ERROR_RX_TIMEOUT [6:6]
/// Source: SIE_STATUS.RX_TIMEOUT
ERROR_RX_TIMEOUT: u1 = 0,
/// ERROR_RX_OVERFLOW [7:7]
/// Source: SIE_STATUS.RX_OVERFLOW
ERROR_RX_OVERFLOW: u1 = 0,
/// ERROR_BIT_STUFF [8:8]
/// Source: SIE_STATUS.BIT_STUFF_ERROR
ERROR_BIT_STUFF: u1 = 0,
/// ERROR_CRC [9:9]
/// Source: SIE_STATUS.CRC_ERROR
ERROR_CRC: u1 = 0,
/// STALL [10:10]
/// Source: SIE_STATUS.STALL_REC
STALL: u1 = 0,
/// VBUS_DETECT [11:11]
/// Source: SIE_STATUS.VBUS_DETECT
VBUS_DETECT: u1 = 0,
/// BUS_RESET [12:12]
/// Source: SIE_STATUS.BUS_RESET
BUS_RESET: u1 = 0,
/// DEV_CONN_DIS [13:13]
/// Set when the device connection state changes. Cleared by writing to SIE_STATUS.CONNECTED
DEV_CONN_DIS: u1 = 0,
/// DEV_SUSPEND [14:14]
/// Set when the device suspend state changes. Cleared by writing to SIE_STATUS.SUSPENDED
DEV_SUSPEND: u1 = 0,
/// DEV_RESUME_FROM_HOST [15:15]
/// Set when the device receives a resume from the host. Cleared by writing to SIE_STATUS.RESUME
DEV_RESUME_FROM_HOST: u1 = 0,
/// SETUP_REQ [16:16]
/// Device. Source: SIE_STATUS.SETUP_REC
SETUP_REQ: u1 = 0,
/// DEV_SOF [17:17]
/// Set every time the device receives a SOF (Start of Frame) packet. Cleared by reading SOF_RD
DEV_SOF: u1 = 0,
/// ABORT_DONE [18:18]
/// Raised when any bit in ABORT_DONE is set. Clear by clearing all bits in ABORT_DONE.
ABORT_DONE: u1 = 0,
/// EP_STALL_NAK [19:19]
/// Raised when any bit in EP_STATUS_STALL_NAK is set. Clear by clearing all bits in EP_STATUS_STALL_NAK.
EP_STALL_NAK: u1 = 0,
/// unused [20:31]
_unused20: u4 = 0,
_unused24: u8 = 0,
};
/// Interrupt Force
pub const INTF = Register(INTF_val).init(base_address + 0x94);

/// INTE
const INTE_val = packed struct {
/// HOST_CONN_DIS [0:0]
/// Host: raised when a device is connected or disconnected (i.e. when SIE_STATUS.SPEED changes). Cleared by writing to SIE_STATUS.SPEED
HOST_CONN_DIS: u1 = 0,
/// HOST_RESUME [1:1]
/// Host: raised when a device wakes up the host. Cleared by writing to SIE_STATUS.RESUME
HOST_RESUME: u1 = 0,
/// HOST_SOF [2:2]
/// Host: raised every time the host sends a SOF (Start of Frame). Cleared by reading SOF_RD
HOST_SOF: u1 = 0,
/// TRANS_COMPLETE [3:3]
/// Raised every time SIE_STATUS.TRANS_COMPLETE is set. Clear by writing to this bit.
TRANS_COMPLETE: u1 = 0,
/// BUFF_STATUS [4:4]
/// Raised when any bit in BUFF_STATUS is set. Clear by clearing all bits in BUFF_STATUS.
BUFF_STATUS: u1 = 0,
/// ERROR_DATA_SEQ [5:5]
/// Source: SIE_STATUS.DATA_SEQ_ERROR
ERROR_DATA_SEQ: u1 = 0,
/// ERROR_RX_TIMEOUT [6:6]
/// Source: SIE_STATUS.RX_TIMEOUT
ERROR_RX_TIMEOUT: u1 = 0,
/// ERROR_RX_OVERFLOW [7:7]
/// Source: SIE_STATUS.RX_OVERFLOW
ERROR_RX_OVERFLOW: u1 = 0,
/// ERROR_BIT_STUFF [8:8]
/// Source: SIE_STATUS.BIT_STUFF_ERROR
ERROR_BIT_STUFF: u1 = 0,
/// ERROR_CRC [9:9]
/// Source: SIE_STATUS.CRC_ERROR
ERROR_CRC: u1 = 0,
/// STALL [10:10]
/// Source: SIE_STATUS.STALL_REC
STALL: u1 = 0,
/// VBUS_DETECT [11:11]
/// Source: SIE_STATUS.VBUS_DETECT
VBUS_DETECT: u1 = 0,
/// BUS_RESET [12:12]
/// Source: SIE_STATUS.BUS_RESET
BUS_RESET: u1 = 0,
/// DEV_CONN_DIS [13:13]
/// Set when the device connection state changes. Cleared by writing to SIE_STATUS.CONNECTED
DEV_CONN_DIS: u1 = 0,
/// DEV_SUSPEND [14:14]
/// Set when the device suspend state changes. Cleared by writing to SIE_STATUS.SUSPENDED
DEV_SUSPEND: u1 = 0,
/// DEV_RESUME_FROM_HOST [15:15]
/// Set when the device receives a resume from the host. Cleared by writing to SIE_STATUS.RESUME
DEV_RESUME_FROM_HOST: u1 = 0,
/// SETUP_REQ [16:16]
/// Device. Source: SIE_STATUS.SETUP_REC
SETUP_REQ: u1 = 0,
/// DEV_SOF [17:17]
/// Set every time the device receives a SOF (Start of Frame) packet. Cleared by reading SOF_RD
DEV_SOF: u1 = 0,
/// ABORT_DONE [18:18]
/// Raised when any bit in ABORT_DONE is set. Clear by clearing all bits in ABORT_DONE.
ABORT_DONE: u1 = 0,
/// EP_STALL_NAK [19:19]
/// Raised when any bit in EP_STATUS_STALL_NAK is set. Clear by clearing all bits in EP_STATUS_STALL_NAK.
EP_STALL_NAK: u1 = 0,
/// unused [20:31]
_unused20: u4 = 0,
_unused24: u8 = 0,
};
/// Interrupt Enable
pub const INTE = Register(INTE_val).init(base_address + 0x90);

/// INTR
const INTR_val = packed struct {
/// HOST_CONN_DIS [0:0]
/// Host: raised when a device is connected or disconnected (i.e. when SIE_STATUS.SPEED changes). Cleared by writing to SIE_STATUS.SPEED
HOST_CONN_DIS: u1 = 0,
/// HOST_RESUME [1:1]
/// Host: raised when a device wakes up the host. Cleared by writing to SIE_STATUS.RESUME
HOST_RESUME: u1 = 0,
/// HOST_SOF [2:2]
/// Host: raised every time the host sends a SOF (Start of Frame). Cleared by reading SOF_RD
HOST_SOF: u1 = 0,
/// TRANS_COMPLETE [3:3]
/// Raised every time SIE_STATUS.TRANS_COMPLETE is set. Clear by writing to this bit.
TRANS_COMPLETE: u1 = 0,
/// BUFF_STATUS [4:4]
/// Raised when any bit in BUFF_STATUS is set. Clear by clearing all bits in BUFF_STATUS.
BUFF_STATUS: u1 = 0,
/// ERROR_DATA_SEQ [5:5]
/// Source: SIE_STATUS.DATA_SEQ_ERROR
ERROR_DATA_SEQ: u1 = 0,
/// ERROR_RX_TIMEOUT [6:6]
/// Source: SIE_STATUS.RX_TIMEOUT
ERROR_RX_TIMEOUT: u1 = 0,
/// ERROR_RX_OVERFLOW [7:7]
/// Source: SIE_STATUS.RX_OVERFLOW
ERROR_RX_OVERFLOW: u1 = 0,
/// ERROR_BIT_STUFF [8:8]
/// Source: SIE_STATUS.BIT_STUFF_ERROR
ERROR_BIT_STUFF: u1 = 0,
/// ERROR_CRC [9:9]
/// Source: SIE_STATUS.CRC_ERROR
ERROR_CRC: u1 = 0,
/// STALL [10:10]
/// Source: SIE_STATUS.STALL_REC
STALL: u1 = 0,
/// VBUS_DETECT [11:11]
/// Source: SIE_STATUS.VBUS_DETECT
VBUS_DETECT: u1 = 0,
/// BUS_RESET [12:12]
/// Source: SIE_STATUS.BUS_RESET
BUS_RESET: u1 = 0,
/// DEV_CONN_DIS [13:13]
/// Set when the device connection state changes. Cleared by writing to SIE_STATUS.CONNECTED
DEV_CONN_DIS: u1 = 0,
/// DEV_SUSPEND [14:14]
/// Set when the device suspend state changes. Cleared by writing to SIE_STATUS.SUSPENDED
DEV_SUSPEND: u1 = 0,
/// DEV_RESUME_FROM_HOST [15:15]
/// Set when the device receives a resume from the host. Cleared by writing to SIE_STATUS.RESUME
DEV_RESUME_FROM_HOST: u1 = 0,
/// SETUP_REQ [16:16]
/// Device. Source: SIE_STATUS.SETUP_REC
SETUP_REQ: u1 = 0,
/// DEV_SOF [17:17]
/// Set every time the device receives a SOF (Start of Frame) packet. Cleared by reading SOF_RD
DEV_SOF: u1 = 0,
/// ABORT_DONE [18:18]
/// Raised when any bit in ABORT_DONE is set. Clear by clearing all bits in ABORT_DONE.
ABORT_DONE: u1 = 0,
/// EP_STALL_NAK [19:19]
/// Raised when any bit in EP_STATUS_STALL_NAK is set. Clear by clearing all bits in EP_STATUS_STALL_NAK.
EP_STALL_NAK: u1 = 0,
/// unused [20:31]
_unused20: u4 = 0,
_unused24: u8 = 0,
};
/// Raw Interrupts
pub const INTR = Register(INTR_val).init(base_address + 0x8c);

/// USBPHY_TRIM
const USBPHY_TRIM_val = packed struct {
/// DP_PULLDN_TRIM [0:4]
/// Value to drive to USB PHY\n
DP_PULLDN_TRIM: u5 = 31,
/// unused [5:7]
_unused5: u3 = 0,
/// DM_PULLDN_TRIM [8:12]
/// Value to drive to USB PHY\n
DM_PULLDN_TRIM: u5 = 31,
/// unused [13:31]
_unused13: u3 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Used to adjust trim values of USB phy pull down resistors.
pub const USBPHY_TRIM = Register(USBPHY_TRIM_val).init(base_address + 0x84);

/// USBPHY_DIRECT_OVERRIDE
const USBPHY_DIRECT_OVERRIDE_val = packed struct {
/// DP_PULLUP_HISEL_OVERRIDE_EN [0:0]
/// No description
DP_PULLUP_HISEL_OVERRIDE_EN: u1 = 0,
/// DM_PULLUP_HISEL_OVERRIDE_EN [1:1]
/// No description
DM_PULLUP_HISEL_OVERRIDE_EN: u1 = 0,
/// DP_PULLUP_EN_OVERRIDE_EN [2:2]
/// No description
DP_PULLUP_EN_OVERRIDE_EN: u1 = 0,
/// DP_PULLDN_EN_OVERRIDE_EN [3:3]
/// No description
DP_PULLDN_EN_OVERRIDE_EN: u1 = 0,
/// DM_PULLDN_EN_OVERRIDE_EN [4:4]
/// No description
DM_PULLDN_EN_OVERRIDE_EN: u1 = 0,
/// TX_DP_OE_OVERRIDE_EN [5:5]
/// No description
TX_DP_OE_OVERRIDE_EN: u1 = 0,
/// TX_DM_OE_OVERRIDE_EN [6:6]
/// No description
TX_DM_OE_OVERRIDE_EN: u1 = 0,
/// TX_DP_OVERRIDE_EN [7:7]
/// No description
TX_DP_OVERRIDE_EN: u1 = 0,
/// TX_DM_OVERRIDE_EN [8:8]
/// No description
TX_DM_OVERRIDE_EN: u1 = 0,
/// RX_PD_OVERRIDE_EN [9:9]
/// No description
RX_PD_OVERRIDE_EN: u1 = 0,
/// TX_PD_OVERRIDE_EN [10:10]
/// No description
TX_PD_OVERRIDE_EN: u1 = 0,
/// TX_FSSLEW_OVERRIDE_EN [11:11]
/// No description
TX_FSSLEW_OVERRIDE_EN: u1 = 0,
/// DM_PULLUP_OVERRIDE_EN [12:12]
/// No description
DM_PULLUP_OVERRIDE_EN: u1 = 0,
/// unused [13:14]
_unused13: u2 = 0,
/// TX_DIFFMODE_OVERRIDE_EN [15:15]
/// No description
TX_DIFFMODE_OVERRIDE_EN: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Override enable for each control in usbphy_direct
pub const USBPHY_DIRECT_OVERRIDE = Register(USBPHY_DIRECT_OVERRIDE_val).init(base_address + 0x80);

/// USBPHY_DIRECT
const USBPHY_DIRECT_val = packed struct {
/// DP_PULLUP_HISEL [0:0]
/// Enable the second DP pull up resistor. 0 - Pull = Rpu2; 1 - Pull = Rpu1 + Rpu2
DP_PULLUP_HISEL: u1 = 0,
/// DP_PULLUP_EN [1:1]
/// DP pull up enable
DP_PULLUP_EN: u1 = 0,
/// DP_PULLDN_EN [2:2]
/// DP pull down enable
DP_PULLDN_EN: u1 = 0,
/// unused [3:3]
_unused3: u1 = 0,
/// DM_PULLUP_HISEL [4:4]
/// Enable the second DM pull up resistor. 0 - Pull = Rpu2; 1 - Pull = Rpu1 + Rpu2
DM_PULLUP_HISEL: u1 = 0,
/// DM_PULLUP_EN [5:5]
/// DM pull up enable
DM_PULLUP_EN: u1 = 0,
/// DM_PULLDN_EN [6:6]
/// DM pull down enable
DM_PULLDN_EN: u1 = 0,
/// unused [7:7]
_unused7: u1 = 0,
/// TX_DP_OE [8:8]
/// Output enable. If TX_DIFFMODE=1, OE for DPP/DPM diff pair. 0 - DPP/DPM in Hi-Z state; 1 - DPP/DPM driving\n
TX_DP_OE: u1 = 0,
/// TX_DM_OE [9:9]
/// Output enable. If TX_DIFFMODE=1, Ignored.\n
TX_DM_OE: u1 = 0,
/// TX_DP [10:10]
/// Output data. If TX_DIFFMODE=1, Drives DPP/DPM diff pair. TX_DP_OE=1 to enable drive. DPP=TX_DP, DPM=~TX_DP\n
TX_DP: u1 = 0,
/// TX_DM [11:11]
/// Output data. TX_DIFFMODE=1, Ignored\n
TX_DM: u1 = 0,
/// RX_PD [12:12]
/// RX power down override (if override enable is set). 1 = powered down.
RX_PD: u1 = 0,
/// TX_PD [13:13]
/// TX power down override (if override enable is set). 1 = powered down.
TX_PD: u1 = 0,
/// TX_FSSLEW [14:14]
/// TX_FSSLEW=0: Low speed slew rate\n
TX_FSSLEW: u1 = 0,
/// TX_DIFFMODE [15:15]
/// TX_DIFFMODE=0: Single ended mode\n
TX_DIFFMODE: u1 = 0,
/// RX_DD [16:16]
/// Differential RX
RX_DD: u1 = 0,
/// RX_DP [17:17]
/// DPP pin state
RX_DP: u1 = 0,
/// RX_DM [18:18]
/// DPM pin state
RX_DM: u1 = 0,
/// DP_OVCN [19:19]
/// DP overcurrent
DP_OVCN: u1 = 0,
/// DM_OVCN [20:20]
/// DM overcurrent
DM_OVCN: u1 = 0,
/// DP_OVV [21:21]
/// DP over voltage
DP_OVV: u1 = 0,
/// DM_OVV [22:22]
/// DM over voltage
DM_OVV: u1 = 0,
/// unused [23:31]
_unused23: u1 = 0,
_unused24: u8 = 0,
};
/// This register allows for direct control of the USB phy. Use in conjunction with usbphy_direct_override register to enable each override bit.
pub const USBPHY_DIRECT = Register(USBPHY_DIRECT_val).init(base_address + 0x7c);

/// USB_PWR
const USB_PWR_val = packed struct {
/// VBUS_EN [0:0]
/// No description
VBUS_EN: u1 = 0,
/// VBUS_EN_OVERRIDE_EN [1:1]
/// No description
VBUS_EN_OVERRIDE_EN: u1 = 0,
/// VBUS_DETECT [2:2]
/// No description
VBUS_DETECT: u1 = 0,
/// VBUS_DETECT_OVERRIDE_EN [3:3]
/// No description
VBUS_DETECT_OVERRIDE_EN: u1 = 0,
/// OVERCURR_DETECT [4:4]
/// No description
OVERCURR_DETECT: u1 = 0,
/// OVERCURR_DETECT_EN [5:5]
/// No description
OVERCURR_DETECT_EN: u1 = 0,
/// unused [6:31]
_unused6: u2 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Overrides for the power signals in the event that the VBUS signals are not hooked up to GPIO. Set the value of the override and then the override enable to switch over to the override value.
pub const USB_PWR = Register(USB_PWR_val).init(base_address + 0x78);

/// USB_MUXING
const USB_MUXING_val = packed struct {
/// TO_PHY [0:0]
/// No description
TO_PHY: u1 = 0,
/// TO_EXTPHY [1:1]
/// No description
TO_EXTPHY: u1 = 0,
/// TO_DIGITAL_PAD [2:2]
/// No description
TO_DIGITAL_PAD: u1 = 0,
/// SOFTCON [3:3]
/// No description
SOFTCON: u1 = 0,
/// unused [4:31]
_unused4: u4 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Where to connect the USB controller. Should be to_phy by default.
pub const USB_MUXING = Register(USB_MUXING_val).init(base_address + 0x74);

/// EP_STATUS_STALL_NAK
const EP_STATUS_STALL_NAK_val = packed struct {
/// EP0_IN [0:0]
/// No description
EP0_IN: u1 = 0,
/// EP0_OUT [1:1]
/// No description
EP0_OUT: u1 = 0,
/// EP1_IN [2:2]
/// No description
EP1_IN: u1 = 0,
/// EP1_OUT [3:3]
/// No description
EP1_OUT: u1 = 0,
/// EP2_IN [4:4]
/// No description
EP2_IN: u1 = 0,
/// EP2_OUT [5:5]
/// No description
EP2_OUT: u1 = 0,
/// EP3_IN [6:6]
/// No description
EP3_IN: u1 = 0,
/// EP3_OUT [7:7]
/// No description
EP3_OUT: u1 = 0,
/// EP4_IN [8:8]
/// No description
EP4_IN: u1 = 0,
/// EP4_OUT [9:9]
/// No description
EP4_OUT: u1 = 0,
/// EP5_IN [10:10]
/// No description
EP5_IN: u1 = 0,
/// EP5_OUT [11:11]
/// No description
EP5_OUT: u1 = 0,
/// EP6_IN [12:12]
/// No description
EP6_IN: u1 = 0,
/// EP6_OUT [13:13]
/// No description
EP6_OUT: u1 = 0,
/// EP7_IN [14:14]
/// No description
EP7_IN: u1 = 0,
/// EP7_OUT [15:15]
/// No description
EP7_OUT: u1 = 0,
/// EP8_IN [16:16]
/// No description
EP8_IN: u1 = 0,
/// EP8_OUT [17:17]
/// No description
EP8_OUT: u1 = 0,
/// EP9_IN [18:18]
/// No description
EP9_IN: u1 = 0,
/// EP9_OUT [19:19]
/// No description
EP9_OUT: u1 = 0,
/// EP10_IN [20:20]
/// No description
EP10_IN: u1 = 0,
/// EP10_OUT [21:21]
/// No description
EP10_OUT: u1 = 0,
/// EP11_IN [22:22]
/// No description
EP11_IN: u1 = 0,
/// EP11_OUT [23:23]
/// No description
EP11_OUT: u1 = 0,
/// EP12_IN [24:24]
/// No description
EP12_IN: u1 = 0,
/// EP12_OUT [25:25]
/// No description
EP12_OUT: u1 = 0,
/// EP13_IN [26:26]
/// No description
EP13_IN: u1 = 0,
/// EP13_OUT [27:27]
/// No description
EP13_OUT: u1 = 0,
/// EP14_IN [28:28]
/// No description
EP14_IN: u1 = 0,
/// EP14_OUT [29:29]
/// No description
EP14_OUT: u1 = 0,
/// EP15_IN [30:30]
/// No description
EP15_IN: u1 = 0,
/// EP15_OUT [31:31]
/// No description
EP15_OUT: u1 = 0,
};
/// Device: bits are set when the `IRQ_ON_NAK` or `IRQ_ON_STALL` bits are set. For EP0 this comes from `SIE_CTRL`. For all other endpoints it comes from the endpoint control register.
pub const EP_STATUS_STALL_NAK = Register(EP_STATUS_STALL_NAK_val).init(base_address + 0x70);

/// NAK_POLL
const NAK_POLL_val = packed struct {
/// DELAY_LS [0:9]
/// NAK polling interval for a low speed device
DELAY_LS: u10 = 16,
/// unused [10:15]
_unused10: u6 = 0,
/// DELAY_FS [16:25]
/// NAK polling interval for a full speed device
DELAY_FS: u10 = 16,
/// unused [26:31]
_unused26: u6 = 0,
};
/// Used by the host controller. Sets the wait time in microseconds before trying again if the device replies with a NAK.
pub const NAK_POLL = Register(NAK_POLL_val).init(base_address + 0x6c);

/// EP_STALL_ARM
const EP_STALL_ARM_val = packed struct {
/// EP0_IN [0:0]
/// No description
EP0_IN: u1 = 0,
/// EP0_OUT [1:1]
/// No description
EP0_OUT: u1 = 0,
/// unused [2:31]
_unused2: u6 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Device: this bit must be set in conjunction with the `STALL` bit in the buffer control register to send a STALL on EP0. The device controller clears these bits when a SETUP packet is received because the USB spec requires that a STALL condition is cleared when a SETUP packet is received.
pub const EP_STALL_ARM = Register(EP_STALL_ARM_val).init(base_address + 0x68);

/// EP_ABORT_DONE
const EP_ABORT_DONE_val = packed struct {
/// EP0_IN [0:0]
/// No description
EP0_IN: u1 = 0,
/// EP0_OUT [1:1]
/// No description
EP0_OUT: u1 = 0,
/// EP1_IN [2:2]
/// No description
EP1_IN: u1 = 0,
/// EP1_OUT [3:3]
/// No description
EP1_OUT: u1 = 0,
/// EP2_IN [4:4]
/// No description
EP2_IN: u1 = 0,
/// EP2_OUT [5:5]
/// No description
EP2_OUT: u1 = 0,
/// EP3_IN [6:6]
/// No description
EP3_IN: u1 = 0,
/// EP3_OUT [7:7]
/// No description
EP3_OUT: u1 = 0,
/// EP4_IN [8:8]
/// No description
EP4_IN: u1 = 0,
/// EP4_OUT [9:9]
/// No description
EP4_OUT: u1 = 0,
/// EP5_IN [10:10]
/// No description
EP5_IN: u1 = 0,
/// EP5_OUT [11:11]
/// No description
EP5_OUT: u1 = 0,
/// EP6_IN [12:12]
/// No description
EP6_IN: u1 = 0,
/// EP6_OUT [13:13]
/// No description
EP6_OUT: u1 = 0,
/// EP7_IN [14:14]
/// No description
EP7_IN: u1 = 0,
/// EP7_OUT [15:15]
/// No description
EP7_OUT: u1 = 0,
/// EP8_IN [16:16]
/// No description
EP8_IN: u1 = 0,
/// EP8_OUT [17:17]
/// No description
EP8_OUT: u1 = 0,
/// EP9_IN [18:18]
/// No description
EP9_IN: u1 = 0,
/// EP9_OUT [19:19]
/// No description
EP9_OUT: u1 = 0,
/// EP10_IN [20:20]
/// No description
EP10_IN: u1 = 0,
/// EP10_OUT [21:21]
/// No description
EP10_OUT: u1 = 0,
/// EP11_IN [22:22]
/// No description
EP11_IN: u1 = 0,
/// EP11_OUT [23:23]
/// No description
EP11_OUT: u1 = 0,
/// EP12_IN [24:24]
/// No description
EP12_IN: u1 = 0,
/// EP12_OUT [25:25]
/// No description
EP12_OUT: u1 = 0,
/// EP13_IN [26:26]
/// No description
EP13_IN: u1 = 0,
/// EP13_OUT [27:27]
/// No description
EP13_OUT: u1 = 0,
/// EP14_IN [28:28]
/// No description
EP14_IN: u1 = 0,
/// EP14_OUT [29:29]
/// No description
EP14_OUT: u1 = 0,
/// EP15_IN [30:30]
/// No description
EP15_IN: u1 = 0,
/// EP15_OUT [31:31]
/// No description
EP15_OUT: u1 = 0,
};
/// Device only: Used in conjunction with `EP_ABORT`. Set once an endpoint is idle so the programmer knows it is safe to modify the buffer control register.
pub const EP_ABORT_DONE = Register(EP_ABORT_DONE_val).init(base_address + 0x64);

/// EP_ABORT
const EP_ABORT_val = packed struct {
/// EP0_IN [0:0]
/// No description
EP0_IN: u1 = 0,
/// EP0_OUT [1:1]
/// No description
EP0_OUT: u1 = 0,
/// EP1_IN [2:2]
/// No description
EP1_IN: u1 = 0,
/// EP1_OUT [3:3]
/// No description
EP1_OUT: u1 = 0,
/// EP2_IN [4:4]
/// No description
EP2_IN: u1 = 0,
/// EP2_OUT [5:5]
/// No description
EP2_OUT: u1 = 0,
/// EP3_IN [6:6]
/// No description
EP3_IN: u1 = 0,
/// EP3_OUT [7:7]
/// No description
EP3_OUT: u1 = 0,
/// EP4_IN [8:8]
/// No description
EP4_IN: u1 = 0,
/// EP4_OUT [9:9]
/// No description
EP4_OUT: u1 = 0,
/// EP5_IN [10:10]
/// No description
EP5_IN: u1 = 0,
/// EP5_OUT [11:11]
/// No description
EP5_OUT: u1 = 0,
/// EP6_IN [12:12]
/// No description
EP6_IN: u1 = 0,
/// EP6_OUT [13:13]
/// No description
EP6_OUT: u1 = 0,
/// EP7_IN [14:14]
/// No description
EP7_IN: u1 = 0,
/// EP7_OUT [15:15]
/// No description
EP7_OUT: u1 = 0,
/// EP8_IN [16:16]
/// No description
EP8_IN: u1 = 0,
/// EP8_OUT [17:17]
/// No description
EP8_OUT: u1 = 0,
/// EP9_IN [18:18]
/// No description
EP9_IN: u1 = 0,
/// EP9_OUT [19:19]
/// No description
EP9_OUT: u1 = 0,
/// EP10_IN [20:20]
/// No description
EP10_IN: u1 = 0,
/// EP10_OUT [21:21]
/// No description
EP10_OUT: u1 = 0,
/// EP11_IN [22:22]
/// No description
EP11_IN: u1 = 0,
/// EP11_OUT [23:23]
/// No description
EP11_OUT: u1 = 0,
/// EP12_IN [24:24]
/// No description
EP12_IN: u1 = 0,
/// EP12_OUT [25:25]
/// No description
EP12_OUT: u1 = 0,
/// EP13_IN [26:26]
/// No description
EP13_IN: u1 = 0,
/// EP13_OUT [27:27]
/// No description
EP13_OUT: u1 = 0,
/// EP14_IN [28:28]
/// No description
EP14_IN: u1 = 0,
/// EP14_OUT [29:29]
/// No description
EP14_OUT: u1 = 0,
/// EP15_IN [30:30]
/// No description
EP15_IN: u1 = 0,
/// EP15_OUT [31:31]
/// No description
EP15_OUT: u1 = 0,
};
/// Device only: Can be set to ignore the buffer control register for this endpoint in case you would like to revoke a buffer. A NAK will be sent for every access to the endpoint until this bit is cleared. A corresponding bit in `EP_ABORT_DONE` is set when it is safe to modify the buffer control register.
pub const EP_ABORT = Register(EP_ABORT_val).init(base_address + 0x60);

/// BUFF_CPU_SHOULD_HANDLE
const BUFF_CPU_SHOULD_HANDLE_val = packed struct {
/// EP0_IN [0:0]
/// No description
EP0_IN: u1 = 0,
/// EP0_OUT [1:1]
/// No description
EP0_OUT: u1 = 0,
/// EP1_IN [2:2]
/// No description
EP1_IN: u1 = 0,
/// EP1_OUT [3:3]
/// No description
EP1_OUT: u1 = 0,
/// EP2_IN [4:4]
/// No description
EP2_IN: u1 = 0,
/// EP2_OUT [5:5]
/// No description
EP2_OUT: u1 = 0,
/// EP3_IN [6:6]
/// No description
EP3_IN: u1 = 0,
/// EP3_OUT [7:7]
/// No description
EP3_OUT: u1 = 0,
/// EP4_IN [8:8]
/// No description
EP4_IN: u1 = 0,
/// EP4_OUT [9:9]
/// No description
EP4_OUT: u1 = 0,
/// EP5_IN [10:10]
/// No description
EP5_IN: u1 = 0,
/// EP5_OUT [11:11]
/// No description
EP5_OUT: u1 = 0,
/// EP6_IN [12:12]
/// No description
EP6_IN: u1 = 0,
/// EP6_OUT [13:13]
/// No description
EP6_OUT: u1 = 0,
/// EP7_IN [14:14]
/// No description
EP7_IN: u1 = 0,
/// EP7_OUT [15:15]
/// No description
EP7_OUT: u1 = 0,
/// EP8_IN [16:16]
/// No description
EP8_IN: u1 = 0,
/// EP8_OUT [17:17]
/// No description
EP8_OUT: u1 = 0,
/// EP9_IN [18:18]
/// No description
EP9_IN: u1 = 0,
/// EP9_OUT [19:19]
/// No description
EP9_OUT: u1 = 0,
/// EP10_IN [20:20]
/// No description
EP10_IN: u1 = 0,
/// EP10_OUT [21:21]
/// No description
EP10_OUT: u1 = 0,
/// EP11_IN [22:22]
/// No description
EP11_IN: u1 = 0,
/// EP11_OUT [23:23]
/// No description
EP11_OUT: u1 = 0,
/// EP12_IN [24:24]
/// No description
EP12_IN: u1 = 0,
/// EP12_OUT [25:25]
/// No description
EP12_OUT: u1 = 0,
/// EP13_IN [26:26]
/// No description
EP13_IN: u1 = 0,
/// EP13_OUT [27:27]
/// No description
EP13_OUT: u1 = 0,
/// EP14_IN [28:28]
/// No description
EP14_IN: u1 = 0,
/// EP14_OUT [29:29]
/// No description
EP14_OUT: u1 = 0,
/// EP15_IN [30:30]
/// No description
EP15_IN: u1 = 0,
/// EP15_OUT [31:31]
/// No description
EP15_OUT: u1 = 0,
};
/// Which of the double buffers should be handled. Only valid if using an interrupt per buffer (i.e. not per 2 buffers). Not valid for host interrupt endpoint polling because they are only single buffered.
pub const BUFF_CPU_SHOULD_HANDLE = Register(BUFF_CPU_SHOULD_HANDLE_val).init(base_address + 0x5c);

/// BUFF_STATUS
const BUFF_STATUS_val = packed struct {
/// EP0_IN [0:0]
/// No description
EP0_IN: u1 = 0,
/// EP0_OUT [1:1]
/// No description
EP0_OUT: u1 = 0,
/// EP1_IN [2:2]
/// No description
EP1_IN: u1 = 0,
/// EP1_OUT [3:3]
/// No description
EP1_OUT: u1 = 0,
/// EP2_IN [4:4]
/// No description
EP2_IN: u1 = 0,
/// EP2_OUT [5:5]
/// No description
EP2_OUT: u1 = 0,
/// EP3_IN [6:6]
/// No description
EP3_IN: u1 = 0,
/// EP3_OUT [7:7]
/// No description
EP3_OUT: u1 = 0,
/// EP4_IN [8:8]
/// No description
EP4_IN: u1 = 0,
/// EP4_OUT [9:9]
/// No description
EP4_OUT: u1 = 0,
/// EP5_IN [10:10]
/// No description
EP5_IN: u1 = 0,
/// EP5_OUT [11:11]
/// No description
EP5_OUT: u1 = 0,
/// EP6_IN [12:12]
/// No description
EP6_IN: u1 = 0,
/// EP6_OUT [13:13]
/// No description
EP6_OUT: u1 = 0,
/// EP7_IN [14:14]
/// No description
EP7_IN: u1 = 0,
/// EP7_OUT [15:15]
/// No description
EP7_OUT: u1 = 0,
/// EP8_IN [16:16]
/// No description
EP8_IN: u1 = 0,
/// EP8_OUT [17:17]
/// No description
EP8_OUT: u1 = 0,
/// EP9_IN [18:18]
/// No description
EP9_IN: u1 = 0,
/// EP9_OUT [19:19]
/// No description
EP9_OUT: u1 = 0,
/// EP10_IN [20:20]
/// No description
EP10_IN: u1 = 0,
/// EP10_OUT [21:21]
/// No description
EP10_OUT: u1 = 0,
/// EP11_IN [22:22]
/// No description
EP11_IN: u1 = 0,
/// EP11_OUT [23:23]
/// No description
EP11_OUT: u1 = 0,
/// EP12_IN [24:24]
/// No description
EP12_IN: u1 = 0,
/// EP12_OUT [25:25]
/// No description
EP12_OUT: u1 = 0,
/// EP13_IN [26:26]
/// No description
EP13_IN: u1 = 0,
/// EP13_OUT [27:27]
/// No description
EP13_OUT: u1 = 0,
/// EP14_IN [28:28]
/// No description
EP14_IN: u1 = 0,
/// EP14_OUT [29:29]
/// No description
EP14_OUT: u1 = 0,
/// EP15_IN [30:30]
/// No description
EP15_IN: u1 = 0,
/// EP15_OUT [31:31]
/// No description
EP15_OUT: u1 = 0,
};
/// Buffer status register. A bit set here indicates that a buffer has completed on the endpoint (if the buffer interrupt is enabled). It is possible for 2 buffers to be completed, so clearing the buffer status bit may instantly re set it on the next clock cycle.
pub const BUFF_STATUS = Register(BUFF_STATUS_val).init(base_address + 0x58);

/// INT_EP_CTRL
const INT_EP_CTRL_val = packed struct {
/// unused [0:0]
_unused0: u1 = 0,
/// INT_EP_ACTIVE [1:15]
/// Host: Enable interrupt endpoint 1 -&gt; 15
INT_EP_ACTIVE: u15 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// interrupt endpoint control register
pub const INT_EP_CTRL = Register(INT_EP_CTRL_val).init(base_address + 0x54);

/// SIE_STATUS
const SIE_STATUS_val = packed struct {
/// VBUS_DETECTED [0:0]
/// Device: VBUS Detected
VBUS_DETECTED: u1 = 0,
/// unused [1:1]
_unused1: u1 = 0,
/// LINE_STATE [2:3]
/// USB bus line state
LINE_STATE: u2 = 0,
/// SUSPENDED [4:4]
/// Bus in suspended state. Valid for device and host. Host and device will go into suspend if neither Keep Alive / SOF frames are enabled.
SUSPENDED: u1 = 0,
/// unused [5:7]
_unused5: u3 = 0,
/// SPEED [8:9]
/// Host: device speed. Disconnected = 00, LS = 01, FS = 10
SPEED: u2 = 0,
/// VBUS_OVER_CURR [10:10]
/// VBUS over current detected
VBUS_OVER_CURR: u1 = 0,
/// RESUME [11:11]
/// Host: Device has initiated a remote resume. Device: host has initiated a resume.
RESUME: u1 = 0,
/// unused [12:15]
_unused12: u4 = 0,
/// CONNECTED [16:16]
/// Device: connected
CONNECTED: u1 = 0,
/// SETUP_REC [17:17]
/// Device: Setup packet received
SETUP_REC: u1 = 0,
/// TRANS_COMPLETE [18:18]
/// Transaction complete.\n\n
TRANS_COMPLETE: u1 = 0,
/// BUS_RESET [19:19]
/// Device: bus reset received
BUS_RESET: u1 = 0,
/// unused [20:23]
_unused20: u4 = 0,
/// CRC_ERROR [24:24]
/// CRC Error. Raised by the Serial RX engine.
CRC_ERROR: u1 = 0,
/// BIT_STUFF_ERROR [25:25]
/// Bit Stuff Error. Raised by the Serial RX engine.
BIT_STUFF_ERROR: u1 = 0,
/// RX_OVERFLOW [26:26]
/// RX overflow is raised by the Serial RX engine if the incoming data is too fast.
RX_OVERFLOW: u1 = 0,
/// RX_TIMEOUT [27:27]
/// RX timeout is raised by both the host and device if an ACK is not received in the maximum time specified by the USB spec.
RX_TIMEOUT: u1 = 0,
/// NAK_REC [28:28]
/// Host: NAK received
NAK_REC: u1 = 0,
/// STALL_REC [29:29]
/// Host: STALL received
STALL_REC: u1 = 0,
/// ACK_REC [30:30]
/// ACK received. Raised by both host and device.
ACK_REC: u1 = 0,
/// DATA_SEQ_ERROR [31:31]
/// Data Sequence Error.\n\n
DATA_SEQ_ERROR: u1 = 0,
};
/// SIE status register
pub const SIE_STATUS = Register(SIE_STATUS_val).init(base_address + 0x50);

/// SIE_CTRL
const SIE_CTRL_val = packed struct {
/// START_TRANS [0:0]
/// Host: Start transaction
START_TRANS: u1 = 0,
/// SEND_SETUP [1:1]
/// Host: Send Setup packet
SEND_SETUP: u1 = 0,
/// SEND_DATA [2:2]
/// Host: Send transaction (OUT from host)
SEND_DATA: u1 = 0,
/// RECEIVE_DATA [3:3]
/// Host: Receive transaction (IN to host)
RECEIVE_DATA: u1 = 0,
/// STOP_TRANS [4:4]
/// Host: Stop transaction
STOP_TRANS: u1 = 0,
/// unused [5:5]
_unused5: u1 = 0,
/// PREAMBLE_EN [6:6]
/// Host: Preable enable for LS device on FS hub
PREAMBLE_EN: u1 = 0,
/// unused [7:7]
_unused7: u1 = 0,
/// SOF_SYNC [8:8]
/// Host: Delay packet(s) until after SOF
SOF_SYNC: u1 = 0,
/// SOF_EN [9:9]
/// Host: Enable SOF generation (for full speed bus)
SOF_EN: u1 = 0,
/// KEEP_ALIVE_EN [10:10]
/// Host: Enable keep alive packet (for low speed bus)
KEEP_ALIVE_EN: u1 = 0,
/// VBUS_EN [11:11]
/// Host: Enable VBUS
VBUS_EN: u1 = 0,
/// RESUME [12:12]
/// Device: Remote wakeup. Device can initiate its own resume after suspend.
RESUME: u1 = 0,
/// RESET_BUS [13:13]
/// Host: Reset bus
RESET_BUS: u1 = 0,
/// unused [14:14]
_unused14: u1 = 0,
/// PULLDOWN_EN [15:15]
/// Host: Enable pull down resistors
PULLDOWN_EN: u1 = 0,
/// PULLUP_EN [16:16]
/// Device: Enable pull up resistor
PULLUP_EN: u1 = 0,
/// RPU_OPT [17:17]
/// Device: Pull-up strength (0=1K2, 1=2k3)
RPU_OPT: u1 = 0,
/// TRANSCEIVER_PD [18:18]
/// Power down bus transceiver
TRANSCEIVER_PD: u1 = 0,
/// unused [19:23]
_unused19: u5 = 0,
/// DIRECT_DM [24:24]
/// Direct control of DM
DIRECT_DM: u1 = 0,
/// DIRECT_DP [25:25]
/// Direct control of DP
DIRECT_DP: u1 = 0,
/// DIRECT_EN [26:26]
/// Direct bus drive enable
DIRECT_EN: u1 = 0,
/// EP0_INT_NAK [27:27]
/// Device: Set bit in EP_STATUS_STALL_NAK when EP0 sends a NAK
EP0_INT_NAK: u1 = 0,
/// EP0_INT_2BUF [28:28]
/// Device: Set bit in BUFF_STATUS for every 2 buffers completed on EP0
EP0_INT_2BUF: u1 = 0,
/// EP0_INT_1BUF [29:29]
/// Device: Set bit in BUFF_STATUS for every buffer completed on EP0
EP0_INT_1BUF: u1 = 0,
/// EP0_DOUBLE_BUF [30:30]
/// Device: EP0 single buffered = 0, double buffered = 1
EP0_DOUBLE_BUF: u1 = 0,
/// EP0_INT_STALL [31:31]
/// Device: Set bit in EP_STATUS_STALL_NAK when EP0 sends a STALL
EP0_INT_STALL: u1 = 0,
};
/// SIE control register
pub const SIE_CTRL = Register(SIE_CTRL_val).init(base_address + 0x4c);

/// SOF_RD
const SOF_RD_val = packed struct {
/// COUNT [0:10]
/// No description
COUNT: u11 = 0,
/// unused [11:31]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Read the last SOF (Start of Frame) frame number seen. In device mode the last SOF received from the host. In host mode the last SOF sent by the host.
pub const SOF_RD = Register(SOF_RD_val).init(base_address + 0x48);

/// SOF_WR
const SOF_WR_val = packed struct {
/// COUNT [0:10]
/// No description
COUNT: u11 = 0,
/// unused [11:31]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Set the SOF (Start of Frame) frame number in the host controller. The SOF packet is sent every 1ms and the host will increment the frame number by 1 each time.
pub const SOF_WR = Register(SOF_WR_val).init(base_address + 0x44);

/// MAIN_CTRL
const MAIN_CTRL_val = packed struct {
/// CONTROLLER_EN [0:0]
/// Enable controller
CONTROLLER_EN: u1 = 0,
/// HOST_NDEVICE [1:1]
/// Device mode = 0, Host mode = 1
HOST_NDEVICE: u1 = 0,
/// unused [2:30]
_unused2: u6 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u7 = 0,
/// SIM_TIMING [31:31]
/// Reduced timings for simulation
SIM_TIMING: u1 = 0,
};
/// Main control register
pub const MAIN_CTRL = Register(MAIN_CTRL_val).init(base_address + 0x40);

/// ADDR_ENDP15
const ADDR_ENDP15_val = packed struct {
/// ADDRESS [0:6]
/// Device address
ADDRESS: u7 = 0,
/// unused [7:15]
_unused7: u1 = 0,
_unused8: u8 = 0,
/// ENDPOINT [16:19]
/// Endpoint number of the interrupt endpoint
ENDPOINT: u4 = 0,
/// unused [20:24]
_unused20: u4 = 0,
_unused24: u1 = 0,
/// INTEP_DIR [25:25]
/// Direction of the interrupt endpoint. In=0, Out=1
INTEP_DIR: u1 = 0,
/// INTEP_PREAMBLE [26:26]
/// Interrupt EP requires preamble (is a low speed device on a full speed hub)
INTEP_PREAMBLE: u1 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// Interrupt endpoint 15. Only valid for HOST mode.
pub const ADDR_ENDP15 = Register(ADDR_ENDP15_val).init(base_address + 0x3c);

/// ADDR_ENDP14
const ADDR_ENDP14_val = packed struct {
/// ADDRESS [0:6]
/// Device address
ADDRESS: u7 = 0,
/// unused [7:15]
_unused7: u1 = 0,
_unused8: u8 = 0,
/// ENDPOINT [16:19]
/// Endpoint number of the interrupt endpoint
ENDPOINT: u4 = 0,
/// unused [20:24]
_unused20: u4 = 0,
_unused24: u1 = 0,
/// INTEP_DIR [25:25]
/// Direction of the interrupt endpoint. In=0, Out=1
INTEP_DIR: u1 = 0,
/// INTEP_PREAMBLE [26:26]
/// Interrupt EP requires preamble (is a low speed device on a full speed hub)
INTEP_PREAMBLE: u1 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// Interrupt endpoint 14. Only valid for HOST mode.
pub const ADDR_ENDP14 = Register(ADDR_ENDP14_val).init(base_address + 0x38);

/// ADDR_ENDP13
const ADDR_ENDP13_val = packed struct {
/// ADDRESS [0:6]
/// Device address
ADDRESS: u7 = 0,
/// unused [7:15]
_unused7: u1 = 0,
_unused8: u8 = 0,
/// ENDPOINT [16:19]
/// Endpoint number of the interrupt endpoint
ENDPOINT: u4 = 0,
/// unused [20:24]
_unused20: u4 = 0,
_unused24: u1 = 0,
/// INTEP_DIR [25:25]
/// Direction of the interrupt endpoint. In=0, Out=1
INTEP_DIR: u1 = 0,
/// INTEP_PREAMBLE [26:26]
/// Interrupt EP requires preamble (is a low speed device on a full speed hub)
INTEP_PREAMBLE: u1 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// Interrupt endpoint 13. Only valid for HOST mode.
pub const ADDR_ENDP13 = Register(ADDR_ENDP13_val).init(base_address + 0x34);

/// ADDR_ENDP12
const ADDR_ENDP12_val = packed struct {
/// ADDRESS [0:6]
/// Device address
ADDRESS: u7 = 0,
/// unused [7:15]
_unused7: u1 = 0,
_unused8: u8 = 0,
/// ENDPOINT [16:19]
/// Endpoint number of the interrupt endpoint
ENDPOINT: u4 = 0,
/// unused [20:24]
_unused20: u4 = 0,
_unused24: u1 = 0,
/// INTEP_DIR [25:25]
/// Direction of the interrupt endpoint. In=0, Out=1
INTEP_DIR: u1 = 0,
/// INTEP_PREAMBLE [26:26]
/// Interrupt EP requires preamble (is a low speed device on a full speed hub)
INTEP_PREAMBLE: u1 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// Interrupt endpoint 12. Only valid for HOST mode.
pub const ADDR_ENDP12 = Register(ADDR_ENDP12_val).init(base_address + 0x30);

/// ADDR_ENDP11
const ADDR_ENDP11_val = packed struct {
/// ADDRESS [0:6]
/// Device address
ADDRESS: u7 = 0,
/// unused [7:15]
_unused7: u1 = 0,
_unused8: u8 = 0,
/// ENDPOINT [16:19]
/// Endpoint number of the interrupt endpoint
ENDPOINT: u4 = 0,
/// unused [20:24]
_unused20: u4 = 0,
_unused24: u1 = 0,
/// INTEP_DIR [25:25]
/// Direction of the interrupt endpoint. In=0, Out=1
INTEP_DIR: u1 = 0,
/// INTEP_PREAMBLE [26:26]
/// Interrupt EP requires preamble (is a low speed device on a full speed hub)
INTEP_PREAMBLE: u1 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// Interrupt endpoint 11. Only valid for HOST mode.
pub const ADDR_ENDP11 = Register(ADDR_ENDP11_val).init(base_address + 0x2c);

/// ADDR_ENDP10
const ADDR_ENDP10_val = packed struct {
/// ADDRESS [0:6]
/// Device address
ADDRESS: u7 = 0,
/// unused [7:15]
_unused7: u1 = 0,
_unused8: u8 = 0,
/// ENDPOINT [16:19]
/// Endpoint number of the interrupt endpoint
ENDPOINT: u4 = 0,
/// unused [20:24]
_unused20: u4 = 0,
_unused24: u1 = 0,
/// INTEP_DIR [25:25]
/// Direction of the interrupt endpoint. In=0, Out=1
INTEP_DIR: u1 = 0,
/// INTEP_PREAMBLE [26:26]
/// Interrupt EP requires preamble (is a low speed device on a full speed hub)
INTEP_PREAMBLE: u1 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// Interrupt endpoint 10. Only valid for HOST mode.
pub const ADDR_ENDP10 = Register(ADDR_ENDP10_val).init(base_address + 0x28);

/// ADDR_ENDP9
const ADDR_ENDP9_val = packed struct {
/// ADDRESS [0:6]
/// Device address
ADDRESS: u7 = 0,
/// unused [7:15]
_unused7: u1 = 0,
_unused8: u8 = 0,
/// ENDPOINT [16:19]
/// Endpoint number of the interrupt endpoint
ENDPOINT: u4 = 0,
/// unused [20:24]
_unused20: u4 = 0,
_unused24: u1 = 0,
/// INTEP_DIR [25:25]
/// Direction of the interrupt endpoint. In=0, Out=1
INTEP_DIR: u1 = 0,
/// INTEP_PREAMBLE [26:26]
/// Interrupt EP requires preamble (is a low speed device on a full speed hub)
INTEP_PREAMBLE: u1 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// Interrupt endpoint 9. Only valid for HOST mode.
pub const ADDR_ENDP9 = Register(ADDR_ENDP9_val).init(base_address + 0x24);

/// ADDR_ENDP8
const ADDR_ENDP8_val = packed struct {
/// ADDRESS [0:6]
/// Device address
ADDRESS: u7 = 0,
/// unused [7:15]
_unused7: u1 = 0,
_unused8: u8 = 0,
/// ENDPOINT [16:19]
/// Endpoint number of the interrupt endpoint
ENDPOINT: u4 = 0,
/// unused [20:24]
_unused20: u4 = 0,
_unused24: u1 = 0,
/// INTEP_DIR [25:25]
/// Direction of the interrupt endpoint. In=0, Out=1
INTEP_DIR: u1 = 0,
/// INTEP_PREAMBLE [26:26]
/// Interrupt EP requires preamble (is a low speed device on a full speed hub)
INTEP_PREAMBLE: u1 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// Interrupt endpoint 8. Only valid for HOST mode.
pub const ADDR_ENDP8 = Register(ADDR_ENDP8_val).init(base_address + 0x20);

/// ADDR_ENDP7
const ADDR_ENDP7_val = packed struct {
/// ADDRESS [0:6]
/// Device address
ADDRESS: u7 = 0,
/// unused [7:15]
_unused7: u1 = 0,
_unused8: u8 = 0,
/// ENDPOINT [16:19]
/// Endpoint number of the interrupt endpoint
ENDPOINT: u4 = 0,
/// unused [20:24]
_unused20: u4 = 0,
_unused24: u1 = 0,
/// INTEP_DIR [25:25]
/// Direction of the interrupt endpoint. In=0, Out=1
INTEP_DIR: u1 = 0,
/// INTEP_PREAMBLE [26:26]
/// Interrupt EP requires preamble (is a low speed device on a full speed hub)
INTEP_PREAMBLE: u1 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// Interrupt endpoint 7. Only valid for HOST mode.
pub const ADDR_ENDP7 = Register(ADDR_ENDP7_val).init(base_address + 0x1c);

/// ADDR_ENDP6
const ADDR_ENDP6_val = packed struct {
/// ADDRESS [0:6]
/// Device address
ADDRESS: u7 = 0,
/// unused [7:15]
_unused7: u1 = 0,
_unused8: u8 = 0,
/// ENDPOINT [16:19]
/// Endpoint number of the interrupt endpoint
ENDPOINT: u4 = 0,
/// unused [20:24]
_unused20: u4 = 0,
_unused24: u1 = 0,
/// INTEP_DIR [25:25]
/// Direction of the interrupt endpoint. In=0, Out=1
INTEP_DIR: u1 = 0,
/// INTEP_PREAMBLE [26:26]
/// Interrupt EP requires preamble (is a low speed device on a full speed hub)
INTEP_PREAMBLE: u1 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// Interrupt endpoint 6. Only valid for HOST mode.
pub const ADDR_ENDP6 = Register(ADDR_ENDP6_val).init(base_address + 0x18);

/// ADDR_ENDP5
const ADDR_ENDP5_val = packed struct {
/// ADDRESS [0:6]
/// Device address
ADDRESS: u7 = 0,
/// unused [7:15]
_unused7: u1 = 0,
_unused8: u8 = 0,
/// ENDPOINT [16:19]
/// Endpoint number of the interrupt endpoint
ENDPOINT: u4 = 0,
/// unused [20:24]
_unused20: u4 = 0,
_unused24: u1 = 0,
/// INTEP_DIR [25:25]
/// Direction of the interrupt endpoint. In=0, Out=1
INTEP_DIR: u1 = 0,
/// INTEP_PREAMBLE [26:26]
/// Interrupt EP requires preamble (is a low speed device on a full speed hub)
INTEP_PREAMBLE: u1 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// Interrupt endpoint 5. Only valid for HOST mode.
pub const ADDR_ENDP5 = Register(ADDR_ENDP5_val).init(base_address + 0x14);

/// ADDR_ENDP4
const ADDR_ENDP4_val = packed struct {
/// ADDRESS [0:6]
/// Device address
ADDRESS: u7 = 0,
/// unused [7:15]
_unused7: u1 = 0,
_unused8: u8 = 0,
/// ENDPOINT [16:19]
/// Endpoint number of the interrupt endpoint
ENDPOINT: u4 = 0,
/// unused [20:24]
_unused20: u4 = 0,
_unused24: u1 = 0,
/// INTEP_DIR [25:25]
/// Direction of the interrupt endpoint. In=0, Out=1
INTEP_DIR: u1 = 0,
/// INTEP_PREAMBLE [26:26]
/// Interrupt EP requires preamble (is a low speed device on a full speed hub)
INTEP_PREAMBLE: u1 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// Interrupt endpoint 4. Only valid for HOST mode.
pub const ADDR_ENDP4 = Register(ADDR_ENDP4_val).init(base_address + 0x10);

/// ADDR_ENDP3
const ADDR_ENDP3_val = packed struct {
/// ADDRESS [0:6]
/// Device address
ADDRESS: u7 = 0,
/// unused [7:15]
_unused7: u1 = 0,
_unused8: u8 = 0,
/// ENDPOINT [16:19]
/// Endpoint number of the interrupt endpoint
ENDPOINT: u4 = 0,
/// unused [20:24]
_unused20: u4 = 0,
_unused24: u1 = 0,
/// INTEP_DIR [25:25]
/// Direction of the interrupt endpoint. In=0, Out=1
INTEP_DIR: u1 = 0,
/// INTEP_PREAMBLE [26:26]
/// Interrupt EP requires preamble (is a low speed device on a full speed hub)
INTEP_PREAMBLE: u1 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// Interrupt endpoint 3. Only valid for HOST mode.
pub const ADDR_ENDP3 = Register(ADDR_ENDP3_val).init(base_address + 0xc);

/// ADDR_ENDP2
const ADDR_ENDP2_val = packed struct {
/// ADDRESS [0:6]
/// Device address
ADDRESS: u7 = 0,
/// unused [7:15]
_unused7: u1 = 0,
_unused8: u8 = 0,
/// ENDPOINT [16:19]
/// Endpoint number of the interrupt endpoint
ENDPOINT: u4 = 0,
/// unused [20:24]
_unused20: u4 = 0,
_unused24: u1 = 0,
/// INTEP_DIR [25:25]
/// Direction of the interrupt endpoint. In=0, Out=1
INTEP_DIR: u1 = 0,
/// INTEP_PREAMBLE [26:26]
/// Interrupt EP requires preamble (is a low speed device on a full speed hub)
INTEP_PREAMBLE: u1 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// Interrupt endpoint 2. Only valid for HOST mode.
pub const ADDR_ENDP2 = Register(ADDR_ENDP2_val).init(base_address + 0x8);

/// ADDR_ENDP1
const ADDR_ENDP1_val = packed struct {
/// ADDRESS [0:6]
/// Device address
ADDRESS: u7 = 0,
/// unused [7:15]
_unused7: u1 = 0,
_unused8: u8 = 0,
/// ENDPOINT [16:19]
/// Endpoint number of the interrupt endpoint
ENDPOINT: u4 = 0,
/// unused [20:24]
_unused20: u4 = 0,
_unused24: u1 = 0,
/// INTEP_DIR [25:25]
/// Direction of the interrupt endpoint. In=0, Out=1
INTEP_DIR: u1 = 0,
/// INTEP_PREAMBLE [26:26]
/// Interrupt EP requires preamble (is a low speed device on a full speed hub)
INTEP_PREAMBLE: u1 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// Interrupt endpoint 1. Only valid for HOST mode.
pub const ADDR_ENDP1 = Register(ADDR_ENDP1_val).init(base_address + 0x4);

/// ADDR_ENDP
const ADDR_ENDP_val = packed struct {
/// ADDRESS [0:6]
/// In device mode, the address that the device should respond to. Set in response to a SET_ADDR setup packet from the host. In host mode set to the address of the device to communicate with.
ADDRESS: u7 = 0,
/// unused [7:15]
_unused7: u1 = 0,
_unused8: u8 = 0,
/// ENDPOINT [16:19]
/// Device endpoint to send data to. Only valid for HOST mode.
ENDPOINT: u4 = 0,
/// unused [20:31]
_unused20: u4 = 0,
_unused24: u8 = 0,
};
/// Device address and endpoint control
pub const ADDR_ENDP = Register(ADDR_ENDP_val).init(base_address + 0x0);
};

/// Programmable IO block
pub const PIO0 = struct {

const base_address = 0x50200000;
/// IRQ1_INTS
const IRQ1_INTS_val = packed struct {
/// SM0_RXNEMPTY [0:0]
/// No description
SM0_RXNEMPTY: u1 = 0,
/// SM1_RXNEMPTY [1:1]
/// No description
SM1_RXNEMPTY: u1 = 0,
/// SM2_RXNEMPTY [2:2]
/// No description
SM2_RXNEMPTY: u1 = 0,
/// SM3_RXNEMPTY [3:3]
/// No description
SM3_RXNEMPTY: u1 = 0,
/// SM0_TXNFULL [4:4]
/// No description
SM0_TXNFULL: u1 = 0,
/// SM1_TXNFULL [5:5]
/// No description
SM1_TXNFULL: u1 = 0,
/// SM2_TXNFULL [6:6]
/// No description
SM2_TXNFULL: u1 = 0,
/// SM3_TXNFULL [7:7]
/// No description
SM3_TXNFULL: u1 = 0,
/// SM0 [8:8]
/// No description
SM0: u1 = 0,
/// SM1 [9:9]
/// No description
SM1: u1 = 0,
/// SM2 [10:10]
/// No description
SM2: u1 = 0,
/// SM3 [11:11]
/// No description
SM3: u1 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Interrupt status after masking &amp; forcing for irq1
pub const IRQ1_INTS = Register(IRQ1_INTS_val).init(base_address + 0x140);

/// IRQ1_INTF
const IRQ1_INTF_val = packed struct {
/// SM0_RXNEMPTY [0:0]
/// No description
SM0_RXNEMPTY: u1 = 0,
/// SM1_RXNEMPTY [1:1]
/// No description
SM1_RXNEMPTY: u1 = 0,
/// SM2_RXNEMPTY [2:2]
/// No description
SM2_RXNEMPTY: u1 = 0,
/// SM3_RXNEMPTY [3:3]
/// No description
SM3_RXNEMPTY: u1 = 0,
/// SM0_TXNFULL [4:4]
/// No description
SM0_TXNFULL: u1 = 0,
/// SM1_TXNFULL [5:5]
/// No description
SM1_TXNFULL: u1 = 0,
/// SM2_TXNFULL [6:6]
/// No description
SM2_TXNFULL: u1 = 0,
/// SM3_TXNFULL [7:7]
/// No description
SM3_TXNFULL: u1 = 0,
/// SM0 [8:8]
/// No description
SM0: u1 = 0,
/// SM1 [9:9]
/// No description
SM1: u1 = 0,
/// SM2 [10:10]
/// No description
SM2: u1 = 0,
/// SM3 [11:11]
/// No description
SM3: u1 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Interrupt Force for irq1
pub const IRQ1_INTF = Register(IRQ1_INTF_val).init(base_address + 0x13c);

/// IRQ1_INTE
const IRQ1_INTE_val = packed struct {
/// SM0_RXNEMPTY [0:0]
/// No description
SM0_RXNEMPTY: u1 = 0,
/// SM1_RXNEMPTY [1:1]
/// No description
SM1_RXNEMPTY: u1 = 0,
/// SM2_RXNEMPTY [2:2]
/// No description
SM2_RXNEMPTY: u1 = 0,
/// SM3_RXNEMPTY [3:3]
/// No description
SM3_RXNEMPTY: u1 = 0,
/// SM0_TXNFULL [4:4]
/// No description
SM0_TXNFULL: u1 = 0,
/// SM1_TXNFULL [5:5]
/// No description
SM1_TXNFULL: u1 = 0,
/// SM2_TXNFULL [6:6]
/// No description
SM2_TXNFULL: u1 = 0,
/// SM3_TXNFULL [7:7]
/// No description
SM3_TXNFULL: u1 = 0,
/// SM0 [8:8]
/// No description
SM0: u1 = 0,
/// SM1 [9:9]
/// No description
SM1: u1 = 0,
/// SM2 [10:10]
/// No description
SM2: u1 = 0,
/// SM3 [11:11]
/// No description
SM3: u1 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Interrupt Enable for irq1
pub const IRQ1_INTE = Register(IRQ1_INTE_val).init(base_address + 0x138);

/// IRQ0_INTS
const IRQ0_INTS_val = packed struct {
/// SM0_RXNEMPTY [0:0]
/// No description
SM0_RXNEMPTY: u1 = 0,
/// SM1_RXNEMPTY [1:1]
/// No description
SM1_RXNEMPTY: u1 = 0,
/// SM2_RXNEMPTY [2:2]
/// No description
SM2_RXNEMPTY: u1 = 0,
/// SM3_RXNEMPTY [3:3]
/// No description
SM3_RXNEMPTY: u1 = 0,
/// SM0_TXNFULL [4:4]
/// No description
SM0_TXNFULL: u1 = 0,
/// SM1_TXNFULL [5:5]
/// No description
SM1_TXNFULL: u1 = 0,
/// SM2_TXNFULL [6:6]
/// No description
SM2_TXNFULL: u1 = 0,
/// SM3_TXNFULL [7:7]
/// No description
SM3_TXNFULL: u1 = 0,
/// SM0 [8:8]
/// No description
SM0: u1 = 0,
/// SM1 [9:9]
/// No description
SM1: u1 = 0,
/// SM2 [10:10]
/// No description
SM2: u1 = 0,
/// SM3 [11:11]
/// No description
SM3: u1 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Interrupt status after masking &amp; forcing for irq0
pub const IRQ0_INTS = Register(IRQ0_INTS_val).init(base_address + 0x134);

/// IRQ0_INTF
const IRQ0_INTF_val = packed struct {
/// SM0_RXNEMPTY [0:0]
/// No description
SM0_RXNEMPTY: u1 = 0,
/// SM1_RXNEMPTY [1:1]
/// No description
SM1_RXNEMPTY: u1 = 0,
/// SM2_RXNEMPTY [2:2]
/// No description
SM2_RXNEMPTY: u1 = 0,
/// SM3_RXNEMPTY [3:3]
/// No description
SM3_RXNEMPTY: u1 = 0,
/// SM0_TXNFULL [4:4]
/// No description
SM0_TXNFULL: u1 = 0,
/// SM1_TXNFULL [5:5]
/// No description
SM1_TXNFULL: u1 = 0,
/// SM2_TXNFULL [6:6]
/// No description
SM2_TXNFULL: u1 = 0,
/// SM3_TXNFULL [7:7]
/// No description
SM3_TXNFULL: u1 = 0,
/// SM0 [8:8]
/// No description
SM0: u1 = 0,
/// SM1 [9:9]
/// No description
SM1: u1 = 0,
/// SM2 [10:10]
/// No description
SM2: u1 = 0,
/// SM3 [11:11]
/// No description
SM3: u1 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Interrupt Force for irq0
pub const IRQ0_INTF = Register(IRQ0_INTF_val).init(base_address + 0x130);

/// IRQ0_INTE
const IRQ0_INTE_val = packed struct {
/// SM0_RXNEMPTY [0:0]
/// No description
SM0_RXNEMPTY: u1 = 0,
/// SM1_RXNEMPTY [1:1]
/// No description
SM1_RXNEMPTY: u1 = 0,
/// SM2_RXNEMPTY [2:2]
/// No description
SM2_RXNEMPTY: u1 = 0,
/// SM3_RXNEMPTY [3:3]
/// No description
SM3_RXNEMPTY: u1 = 0,
/// SM0_TXNFULL [4:4]
/// No description
SM0_TXNFULL: u1 = 0,
/// SM1_TXNFULL [5:5]
/// No description
SM1_TXNFULL: u1 = 0,
/// SM2_TXNFULL [6:6]
/// No description
SM2_TXNFULL: u1 = 0,
/// SM3_TXNFULL [7:7]
/// No description
SM3_TXNFULL: u1 = 0,
/// SM0 [8:8]
/// No description
SM0: u1 = 0,
/// SM1 [9:9]
/// No description
SM1: u1 = 0,
/// SM2 [10:10]
/// No description
SM2: u1 = 0,
/// SM3 [11:11]
/// No description
SM3: u1 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Interrupt Enable for irq0
pub const IRQ0_INTE = Register(IRQ0_INTE_val).init(base_address + 0x12c);

/// INTR
const INTR_val = packed struct {
/// SM0_RXNEMPTY [0:0]
/// No description
SM0_RXNEMPTY: u1 = 0,
/// SM1_RXNEMPTY [1:1]
/// No description
SM1_RXNEMPTY: u1 = 0,
/// SM2_RXNEMPTY [2:2]
/// No description
SM2_RXNEMPTY: u1 = 0,
/// SM3_RXNEMPTY [3:3]
/// No description
SM3_RXNEMPTY: u1 = 0,
/// SM0_TXNFULL [4:4]
/// No description
SM0_TXNFULL: u1 = 0,
/// SM1_TXNFULL [5:5]
/// No description
SM1_TXNFULL: u1 = 0,
/// SM2_TXNFULL [6:6]
/// No description
SM2_TXNFULL: u1 = 0,
/// SM3_TXNFULL [7:7]
/// No description
SM3_TXNFULL: u1 = 0,
/// SM0 [8:8]
/// No description
SM0: u1 = 0,
/// SM1 [9:9]
/// No description
SM1: u1 = 0,
/// SM2 [10:10]
/// No description
SM2: u1 = 0,
/// SM3 [11:11]
/// No description
SM3: u1 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Raw Interrupts
pub const INTR = Register(INTR_val).init(base_address + 0x128);

/// SM3_PINCTRL
const SM3_PINCTRL_val = packed struct {
/// OUT_BASE [0:4]
/// The lowest-numbered pin that will be affected by an OUT PINS, OUT PINDIRS or MOV PINS instruction. The data written to this pin will always be the least-significant bit of the OUT or MOV data.
OUT_BASE: u5 = 0,
/// SET_BASE [5:9]
/// The lowest-numbered pin that will be affected by a SET PINS or SET PINDIRS instruction. The data written to this pin is the least-significant bit of the SET data.
SET_BASE: u5 = 0,
/// SIDESET_BASE [10:14]
/// The lowest-numbered pin that will be affected by a side-set operation. The MSBs of an instruction's side-set/delay field (up to 5, determined by SIDESET_COUNT) are used for side-set data, with the remaining LSBs used for delay. The least-significant bit of the side-set portion is the bit written to this pin, with more-significant bits written to higher-numbered pins.
SIDESET_BASE: u5 = 0,
/// IN_BASE [15:19]
/// The pin which is mapped to the least-significant bit of a state machine's IN data bus. Higher-numbered pins are mapped to consecutively more-significant data bits, with a modulo of 32 applied to pin number.
IN_BASE: u5 = 0,
/// OUT_COUNT [20:25]
/// The number of pins asserted by an OUT PINS, OUT PINDIRS or MOV PINS instruction. In the range 0 to 32 inclusive.
OUT_COUNT: u6 = 0,
/// SET_COUNT [26:28]
/// The number of pins asserted by a SET. In the range 0 to 5 inclusive.
SET_COUNT: u3 = 5,
/// SIDESET_COUNT [29:31]
/// The number of MSBs of the Delay/Side-set instruction field which are used for side-set. Inclusive of the enable bit, if present. Minimum of 0 (all delay bits, no side-set) and maximum of 5 (all side-set, no delay).
SIDESET_COUNT: u3 = 0,
};
/// State machine pin control
pub const SM3_PINCTRL = Register(SM3_PINCTRL_val).init(base_address + 0x124);

/// SM3_INSTR
const SM3_INSTR_val = packed struct {
/// SM3_INSTR [0:15]
/// No description
SM3_INSTR: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Read to see the instruction currently addressed by state machine 3's program counter\n
pub const SM3_INSTR = Register(SM3_INSTR_val).init(base_address + 0x120);

/// SM3_ADDR
const SM3_ADDR_val = packed struct {
/// SM3_ADDR [0:4]
/// No description
SM3_ADDR: u5 = 0,
/// unused [5:31]
_unused5: u3 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Current instruction address of state machine 3
pub const SM3_ADDR = Register(SM3_ADDR_val).init(base_address + 0x11c);

/// SM3_SHIFTCTRL
const SM3_SHIFTCTRL_val = packed struct {
/// unused [0:15]
_unused0: u8 = 0,
_unused8: u8 = 0,
/// AUTOPUSH [16:16]
/// Push automatically when the input shift register is filled, i.e. on an IN instruction which causes the input shift counter to reach or exceed PUSH_THRESH.
AUTOPUSH: u1 = 0,
/// AUTOPULL [17:17]
/// Pull automatically when the output shift register is emptied, i.e. on or following an OUT instruction which causes the output shift counter to reach or exceed PULL_THRESH.
AUTOPULL: u1 = 0,
/// IN_SHIFTDIR [18:18]
/// 1 = shift input shift register to right (data enters from left). 0 = to left.
IN_SHIFTDIR: u1 = 1,
/// OUT_SHIFTDIR [19:19]
/// 1 = shift out of output shift register to right. 0 = to left.
OUT_SHIFTDIR: u1 = 1,
/// PUSH_THRESH [20:24]
/// Number of bits shifted into ISR before autopush, or conditional push (PUSH IFFULL), will take place.\n
PUSH_THRESH: u5 = 0,
/// PULL_THRESH [25:29]
/// Number of bits shifted out of OSR before autopull, or conditional pull (PULL IFEMPTY), will take place.\n
PULL_THRESH: u5 = 0,
/// FJOIN_TX [30:30]
/// When 1, TX FIFO steals the RX FIFO's storage, and becomes twice as deep.\n
FJOIN_TX: u1 = 0,
/// FJOIN_RX [31:31]
/// When 1, RX FIFO steals the TX FIFO's storage, and becomes twice as deep.\n
FJOIN_RX: u1 = 0,
};
/// Control behaviour of the input/output shift registers for state machine 3
pub const SM3_SHIFTCTRL = Register(SM3_SHIFTCTRL_val).init(base_address + 0x118);

/// SM3_EXECCTRL
const SM3_EXECCTRL_val = packed struct {
/// STATUS_N [0:3]
/// Comparison level for the MOV x, STATUS instruction
STATUS_N: u4 = 0,
/// STATUS_SEL [4:4]
/// Comparison used for the MOV x, STATUS instruction.
STATUS_SEL: u1 = 0,
/// unused [5:6]
_unused5: u2 = 0,
/// WRAP_BOTTOM [7:11]
/// After reaching wrap_top, execution is wrapped to this address.
WRAP_BOTTOM: u5 = 0,
/// WRAP_TOP [12:16]
/// After reaching this address, execution is wrapped to wrap_bottom.\n
WRAP_TOP: u5 = 31,
/// OUT_STICKY [17:17]
/// Continuously assert the most recent OUT/SET to the pins
OUT_STICKY: u1 = 0,
/// INLINE_OUT_EN [18:18]
/// If 1, use a bit of OUT data as an auxiliary write enable\n
INLINE_OUT_EN: u1 = 0,
/// OUT_EN_SEL [19:23]
/// Which data bit to use for inline OUT enable
OUT_EN_SEL: u5 = 0,
/// JMP_PIN [24:28]
/// The GPIO number to use as condition for JMP PIN. Unaffected by input mapping.
JMP_PIN: u5 = 0,
/// SIDE_PINDIR [29:29]
/// If 1, side-set data is asserted to pin directions, instead of pin values
SIDE_PINDIR: u1 = 0,
/// SIDE_EN [30:30]
/// If 1, the MSB of the Delay/Side-set instruction field is used as side-set enable, rather than a side-set data bit. This allows instructions to perform side-set optionally, rather than on every instruction, but the maximum possible side-set width is reduced from 5 to 4. Note that the value of PINCTRL_SIDESET_COUNT is inclusive of this enable bit.
SIDE_EN: u1 = 0,
/// EXEC_STALLED [31:31]
/// If 1, an instruction written to SMx_INSTR is stalled, and latched by the state machine. Will clear to 0 once this instruction completes.
EXEC_STALLED: u1 = 0,
};
/// Execution/behavioural settings for state machine 3
pub const SM3_EXECCTRL = Register(SM3_EXECCTRL_val).init(base_address + 0x114);

/// SM3_CLKDIV
const SM3_CLKDIV_val = packed struct {
/// unused [0:7]
_unused0: u8 = 0,
/// FRAC [8:15]
/// Fractional part of clock divisor
FRAC: u8 = 0,
/// INT [16:31]
/// Effective frequency is sysclk/(int + frac/256).\n
INT: u16 = 1,
};
/// Clock divisor register for state machine 3\n
pub const SM3_CLKDIV = Register(SM3_CLKDIV_val).init(base_address + 0x110);

/// SM2_PINCTRL
const SM2_PINCTRL_val = packed struct {
/// OUT_BASE [0:4]
/// The lowest-numbered pin that will be affected by an OUT PINS, OUT PINDIRS or MOV PINS instruction. The data written to this pin will always be the least-significant bit of the OUT or MOV data.
OUT_BASE: u5 = 0,
/// SET_BASE [5:9]
/// The lowest-numbered pin that will be affected by a SET PINS or SET PINDIRS instruction. The data written to this pin is the least-significant bit of the SET data.
SET_BASE: u5 = 0,
/// SIDESET_BASE [10:14]
/// The lowest-numbered pin that will be affected by a side-set operation. The MSBs of an instruction's side-set/delay field (up to 5, determined by SIDESET_COUNT) are used for side-set data, with the remaining LSBs used for delay. The least-significant bit of the side-set portion is the bit written to this pin, with more-significant bits written to higher-numbered pins.
SIDESET_BASE: u5 = 0,
/// IN_BASE [15:19]
/// The pin which is mapped to the least-significant bit of a state machine's IN data bus. Higher-numbered pins are mapped to consecutively more-significant data bits, with a modulo of 32 applied to pin number.
IN_BASE: u5 = 0,
/// OUT_COUNT [20:25]
/// The number of pins asserted by an OUT PINS, OUT PINDIRS or MOV PINS instruction. In the range 0 to 32 inclusive.
OUT_COUNT: u6 = 0,
/// SET_COUNT [26:28]
/// The number of pins asserted by a SET. In the range 0 to 5 inclusive.
SET_COUNT: u3 = 5,
/// SIDESET_COUNT [29:31]
/// The number of MSBs of the Delay/Side-set instruction field which are used for side-set. Inclusive of the enable bit, if present. Minimum of 0 (all delay bits, no side-set) and maximum of 5 (all side-set, no delay).
SIDESET_COUNT: u3 = 0,
};
/// State machine pin control
pub const SM2_PINCTRL = Register(SM2_PINCTRL_val).init(base_address + 0x10c);

/// SM2_INSTR
const SM2_INSTR_val = packed struct {
/// SM2_INSTR [0:15]
/// No description
SM2_INSTR: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Read to see the instruction currently addressed by state machine 2's program counter\n
pub const SM2_INSTR = Register(SM2_INSTR_val).init(base_address + 0x108);

/// SM2_ADDR
const SM2_ADDR_val = packed struct {
/// SM2_ADDR [0:4]
/// No description
SM2_ADDR: u5 = 0,
/// unused [5:31]
_unused5: u3 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Current instruction address of state machine 2
pub const SM2_ADDR = Register(SM2_ADDR_val).init(base_address + 0x104);

/// SM2_SHIFTCTRL
const SM2_SHIFTCTRL_val = packed struct {
/// unused [0:15]
_unused0: u8 = 0,
_unused8: u8 = 0,
/// AUTOPUSH [16:16]
/// Push automatically when the input shift register is filled, i.e. on an IN instruction which causes the input shift counter to reach or exceed PUSH_THRESH.
AUTOPUSH: u1 = 0,
/// AUTOPULL [17:17]
/// Pull automatically when the output shift register is emptied, i.e. on or following an OUT instruction which causes the output shift counter to reach or exceed PULL_THRESH.
AUTOPULL: u1 = 0,
/// IN_SHIFTDIR [18:18]
/// 1 = shift input shift register to right (data enters from left). 0 = to left.
IN_SHIFTDIR: u1 = 1,
/// OUT_SHIFTDIR [19:19]
/// 1 = shift out of output shift register to right. 0 = to left.
OUT_SHIFTDIR: u1 = 1,
/// PUSH_THRESH [20:24]
/// Number of bits shifted into ISR before autopush, or conditional push (PUSH IFFULL), will take place.\n
PUSH_THRESH: u5 = 0,
/// PULL_THRESH [25:29]
/// Number of bits shifted out of OSR before autopull, or conditional pull (PULL IFEMPTY), will take place.\n
PULL_THRESH: u5 = 0,
/// FJOIN_TX [30:30]
/// When 1, TX FIFO steals the RX FIFO's storage, and becomes twice as deep.\n
FJOIN_TX: u1 = 0,
/// FJOIN_RX [31:31]
/// When 1, RX FIFO steals the TX FIFO's storage, and becomes twice as deep.\n
FJOIN_RX: u1 = 0,
};
/// Control behaviour of the input/output shift registers for state machine 2
pub const SM2_SHIFTCTRL = Register(SM2_SHIFTCTRL_val).init(base_address + 0x100);

/// SM2_EXECCTRL
const SM2_EXECCTRL_val = packed struct {
/// STATUS_N [0:3]
/// Comparison level for the MOV x, STATUS instruction
STATUS_N: u4 = 0,
/// STATUS_SEL [4:4]
/// Comparison used for the MOV x, STATUS instruction.
STATUS_SEL: u1 = 0,
/// unused [5:6]
_unused5: u2 = 0,
/// WRAP_BOTTOM [7:11]
/// After reaching wrap_top, execution is wrapped to this address.
WRAP_BOTTOM: u5 = 0,
/// WRAP_TOP [12:16]
/// After reaching this address, execution is wrapped to wrap_bottom.\n
WRAP_TOP: u5 = 31,
/// OUT_STICKY [17:17]
/// Continuously assert the most recent OUT/SET to the pins
OUT_STICKY: u1 = 0,
/// INLINE_OUT_EN [18:18]
/// If 1, use a bit of OUT data as an auxiliary write enable\n
INLINE_OUT_EN: u1 = 0,
/// OUT_EN_SEL [19:23]
/// Which data bit to use for inline OUT enable
OUT_EN_SEL: u5 = 0,
/// JMP_PIN [24:28]
/// The GPIO number to use as condition for JMP PIN. Unaffected by input mapping.
JMP_PIN: u5 = 0,
/// SIDE_PINDIR [29:29]
/// If 1, side-set data is asserted to pin directions, instead of pin values
SIDE_PINDIR: u1 = 0,
/// SIDE_EN [30:30]
/// If 1, the MSB of the Delay/Side-set instruction field is used as side-set enable, rather than a side-set data bit. This allows instructions to perform side-set optionally, rather than on every instruction, but the maximum possible side-set width is reduced from 5 to 4. Note that the value of PINCTRL_SIDESET_COUNT is inclusive of this enable bit.
SIDE_EN: u1 = 0,
/// EXEC_STALLED [31:31]
/// If 1, an instruction written to SMx_INSTR is stalled, and latched by the state machine. Will clear to 0 once this instruction completes.
EXEC_STALLED: u1 = 0,
};
/// Execution/behavioural settings for state machine 2
pub const SM2_EXECCTRL = Register(SM2_EXECCTRL_val).init(base_address + 0xfc);

/// SM2_CLKDIV
const SM2_CLKDIV_val = packed struct {
/// unused [0:7]
_unused0: u8 = 0,
/// FRAC [8:15]
/// Fractional part of clock divisor
FRAC: u8 = 0,
/// INT [16:31]
/// Effective frequency is sysclk/(int + frac/256).\n
INT: u16 = 1,
};
/// Clock divisor register for state machine 2\n
pub const SM2_CLKDIV = Register(SM2_CLKDIV_val).init(base_address + 0xf8);

/// SM1_PINCTRL
const SM1_PINCTRL_val = packed struct {
/// OUT_BASE [0:4]
/// The lowest-numbered pin that will be affected by an OUT PINS, OUT PINDIRS or MOV PINS instruction. The data written to this pin will always be the least-significant bit of the OUT or MOV data.
OUT_BASE: u5 = 0,
/// SET_BASE [5:9]
/// The lowest-numbered pin that will be affected by a SET PINS or SET PINDIRS instruction. The data written to this pin is the least-significant bit of the SET data.
SET_BASE: u5 = 0,
/// SIDESET_BASE [10:14]
/// The lowest-numbered pin that will be affected by a side-set operation. The MSBs of an instruction's side-set/delay field (up to 5, determined by SIDESET_COUNT) are used for side-set data, with the remaining LSBs used for delay. The least-significant bit of the side-set portion is the bit written to this pin, with more-significant bits written to higher-numbered pins.
SIDESET_BASE: u5 = 0,
/// IN_BASE [15:19]
/// The pin which is mapped to the least-significant bit of a state machine's IN data bus. Higher-numbered pins are mapped to consecutively more-significant data bits, with a modulo of 32 applied to pin number.
IN_BASE: u5 = 0,
/// OUT_COUNT [20:25]
/// The number of pins asserted by an OUT PINS, OUT PINDIRS or MOV PINS instruction. In the range 0 to 32 inclusive.
OUT_COUNT: u6 = 0,
/// SET_COUNT [26:28]
/// The number of pins asserted by a SET. In the range 0 to 5 inclusive.
SET_COUNT: u3 = 5,
/// SIDESET_COUNT [29:31]
/// The number of MSBs of the Delay/Side-set instruction field which are used for side-set. Inclusive of the enable bit, if present. Minimum of 0 (all delay bits, no side-set) and maximum of 5 (all side-set, no delay).
SIDESET_COUNT: u3 = 0,
};
/// State machine pin control
pub const SM1_PINCTRL = Register(SM1_PINCTRL_val).init(base_address + 0xf4);

/// SM1_INSTR
const SM1_INSTR_val = packed struct {
/// SM1_INSTR [0:15]
/// No description
SM1_INSTR: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Read to see the instruction currently addressed by state machine 1's program counter\n
pub const SM1_INSTR = Register(SM1_INSTR_val).init(base_address + 0xf0);

/// SM1_ADDR
const SM1_ADDR_val = packed struct {
/// SM1_ADDR [0:4]
/// No description
SM1_ADDR: u5 = 0,
/// unused [5:31]
_unused5: u3 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Current instruction address of state machine 1
pub const SM1_ADDR = Register(SM1_ADDR_val).init(base_address + 0xec);

/// SM1_SHIFTCTRL
const SM1_SHIFTCTRL_val = packed struct {
/// unused [0:15]
_unused0: u8 = 0,
_unused8: u8 = 0,
/// AUTOPUSH [16:16]
/// Push automatically when the input shift register is filled, i.e. on an IN instruction which causes the input shift counter to reach or exceed PUSH_THRESH.
AUTOPUSH: u1 = 0,
/// AUTOPULL [17:17]
/// Pull automatically when the output shift register is emptied, i.e. on or following an OUT instruction which causes the output shift counter to reach or exceed PULL_THRESH.
AUTOPULL: u1 = 0,
/// IN_SHIFTDIR [18:18]
/// 1 = shift input shift register to right (data enters from left). 0 = to left.
IN_SHIFTDIR: u1 = 1,
/// OUT_SHIFTDIR [19:19]
/// 1 = shift out of output shift register to right. 0 = to left.
OUT_SHIFTDIR: u1 = 1,
/// PUSH_THRESH [20:24]
/// Number of bits shifted into ISR before autopush, or conditional push (PUSH IFFULL), will take place.\n
PUSH_THRESH: u5 = 0,
/// PULL_THRESH [25:29]
/// Number of bits shifted out of OSR before autopull, or conditional pull (PULL IFEMPTY), will take place.\n
PULL_THRESH: u5 = 0,
/// FJOIN_TX [30:30]
/// When 1, TX FIFO steals the RX FIFO's storage, and becomes twice as deep.\n
FJOIN_TX: u1 = 0,
/// FJOIN_RX [31:31]
/// When 1, RX FIFO steals the TX FIFO's storage, and becomes twice as deep.\n
FJOIN_RX: u1 = 0,
};
/// Control behaviour of the input/output shift registers for state machine 1
pub const SM1_SHIFTCTRL = Register(SM1_SHIFTCTRL_val).init(base_address + 0xe8);

/// SM1_EXECCTRL
const SM1_EXECCTRL_val = packed struct {
/// STATUS_N [0:3]
/// Comparison level for the MOV x, STATUS instruction
STATUS_N: u4 = 0,
/// STATUS_SEL [4:4]
/// Comparison used for the MOV x, STATUS instruction.
STATUS_SEL: u1 = 0,
/// unused [5:6]
_unused5: u2 = 0,
/// WRAP_BOTTOM [7:11]
/// After reaching wrap_top, execution is wrapped to this address.
WRAP_BOTTOM: u5 = 0,
/// WRAP_TOP [12:16]
/// After reaching this address, execution is wrapped to wrap_bottom.\n
WRAP_TOP: u5 = 31,
/// OUT_STICKY [17:17]
/// Continuously assert the most recent OUT/SET to the pins
OUT_STICKY: u1 = 0,
/// INLINE_OUT_EN [18:18]
/// If 1, use a bit of OUT data as an auxiliary write enable\n
INLINE_OUT_EN: u1 = 0,
/// OUT_EN_SEL [19:23]
/// Which data bit to use for inline OUT enable
OUT_EN_SEL: u5 = 0,
/// JMP_PIN [24:28]
/// The GPIO number to use as condition for JMP PIN. Unaffected by input mapping.
JMP_PIN: u5 = 0,
/// SIDE_PINDIR [29:29]
/// If 1, side-set data is asserted to pin directions, instead of pin values
SIDE_PINDIR: u1 = 0,
/// SIDE_EN [30:30]
/// If 1, the MSB of the Delay/Side-set instruction field is used as side-set enable, rather than a side-set data bit. This allows instructions to perform side-set optionally, rather than on every instruction, but the maximum possible side-set width is reduced from 5 to 4. Note that the value of PINCTRL_SIDESET_COUNT is inclusive of this enable bit.
SIDE_EN: u1 = 0,
/// EXEC_STALLED [31:31]
/// If 1, an instruction written to SMx_INSTR is stalled, and latched by the state machine. Will clear to 0 once this instruction completes.
EXEC_STALLED: u1 = 0,
};
/// Execution/behavioural settings for state machine 1
pub const SM1_EXECCTRL = Register(SM1_EXECCTRL_val).init(base_address + 0xe4);

/// SM1_CLKDIV
const SM1_CLKDIV_val = packed struct {
/// unused [0:7]
_unused0: u8 = 0,
/// FRAC [8:15]
/// Fractional part of clock divisor
FRAC: u8 = 0,
/// INT [16:31]
/// Effective frequency is sysclk/(int + frac/256).\n
INT: u16 = 1,
};
/// Clock divisor register for state machine 1\n
pub const SM1_CLKDIV = Register(SM1_CLKDIV_val).init(base_address + 0xe0);

/// SM0_PINCTRL
const SM0_PINCTRL_val = packed struct {
/// OUT_BASE [0:4]
/// The lowest-numbered pin that will be affected by an OUT PINS, OUT PINDIRS or MOV PINS instruction. The data written to this pin will always be the least-significant bit of the OUT or MOV data.
OUT_BASE: u5 = 0,
/// SET_BASE [5:9]
/// The lowest-numbered pin that will be affected by a SET PINS or SET PINDIRS instruction. The data written to this pin is the least-significant bit of the SET data.
SET_BASE: u5 = 0,
/// SIDESET_BASE [10:14]
/// The lowest-numbered pin that will be affected by a side-set operation. The MSBs of an instruction's side-set/delay field (up to 5, determined by SIDESET_COUNT) are used for side-set data, with the remaining LSBs used for delay. The least-significant bit of the side-set portion is the bit written to this pin, with more-significant bits written to higher-numbered pins.
SIDESET_BASE: u5 = 0,
/// IN_BASE [15:19]
/// The pin which is mapped to the least-significant bit of a state machine's IN data bus. Higher-numbered pins are mapped to consecutively more-significant data bits, with a modulo of 32 applied to pin number.
IN_BASE: u5 = 0,
/// OUT_COUNT [20:25]
/// The number of pins asserted by an OUT PINS, OUT PINDIRS or MOV PINS instruction. In the range 0 to 32 inclusive.
OUT_COUNT: u6 = 0,
/// SET_COUNT [26:28]
/// The number of pins asserted by a SET. In the range 0 to 5 inclusive.
SET_COUNT: u3 = 5,
/// SIDESET_COUNT [29:31]
/// The number of MSBs of the Delay/Side-set instruction field which are used for side-set. Inclusive of the enable bit, if present. Minimum of 0 (all delay bits, no side-set) and maximum of 5 (all side-set, no delay).
SIDESET_COUNT: u3 = 0,
};
/// State machine pin control
pub const SM0_PINCTRL = Register(SM0_PINCTRL_val).init(base_address + 0xdc);

/// SM0_INSTR
const SM0_INSTR_val = packed struct {
/// SM0_INSTR [0:15]
/// No description
SM0_INSTR: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Read to see the instruction currently addressed by state machine 0's program counter\n
pub const SM0_INSTR = Register(SM0_INSTR_val).init(base_address + 0xd8);

/// SM0_ADDR
const SM0_ADDR_val = packed struct {
/// SM0_ADDR [0:4]
/// No description
SM0_ADDR: u5 = 0,
/// unused [5:31]
_unused5: u3 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Current instruction address of state machine 0
pub const SM0_ADDR = Register(SM0_ADDR_val).init(base_address + 0xd4);

/// SM0_SHIFTCTRL
const SM0_SHIFTCTRL_val = packed struct {
/// unused [0:15]
_unused0: u8 = 0,
_unused8: u8 = 0,
/// AUTOPUSH [16:16]
/// Push automatically when the input shift register is filled, i.e. on an IN instruction which causes the input shift counter to reach or exceed PUSH_THRESH.
AUTOPUSH: u1 = 0,
/// AUTOPULL [17:17]
/// Pull automatically when the output shift register is emptied, i.e. on or following an OUT instruction which causes the output shift counter to reach or exceed PULL_THRESH.
AUTOPULL: u1 = 0,
/// IN_SHIFTDIR [18:18]
/// 1 = shift input shift register to right (data enters from left). 0 = to left.
IN_SHIFTDIR: u1 = 1,
/// OUT_SHIFTDIR [19:19]
/// 1 = shift out of output shift register to right. 0 = to left.
OUT_SHIFTDIR: u1 = 1,
/// PUSH_THRESH [20:24]
/// Number of bits shifted into ISR before autopush, or conditional push (PUSH IFFULL), will take place.\n
PUSH_THRESH: u5 = 0,
/// PULL_THRESH [25:29]
/// Number of bits shifted out of OSR before autopull, or conditional pull (PULL IFEMPTY), will take place.\n
PULL_THRESH: u5 = 0,
/// FJOIN_TX [30:30]
/// When 1, TX FIFO steals the RX FIFO's storage, and becomes twice as deep.\n
FJOIN_TX: u1 = 0,
/// FJOIN_RX [31:31]
/// When 1, RX FIFO steals the TX FIFO's storage, and becomes twice as deep.\n
FJOIN_RX: u1 = 0,
};
/// Control behaviour of the input/output shift registers for state machine 0
pub const SM0_SHIFTCTRL = Register(SM0_SHIFTCTRL_val).init(base_address + 0xd0);

/// SM0_EXECCTRL
const SM0_EXECCTRL_val = packed struct {
/// STATUS_N [0:3]
/// Comparison level for the MOV x, STATUS instruction
STATUS_N: u4 = 0,
/// STATUS_SEL [4:4]
/// Comparison used for the MOV x, STATUS instruction.
STATUS_SEL: u1 = 0,
/// unused [5:6]
_unused5: u2 = 0,
/// WRAP_BOTTOM [7:11]
/// After reaching wrap_top, execution is wrapped to this address.
WRAP_BOTTOM: u5 = 0,
/// WRAP_TOP [12:16]
/// After reaching this address, execution is wrapped to wrap_bottom.\n
WRAP_TOP: u5 = 31,
/// OUT_STICKY [17:17]
/// Continuously assert the most recent OUT/SET to the pins
OUT_STICKY: u1 = 0,
/// INLINE_OUT_EN [18:18]
/// If 1, use a bit of OUT data as an auxiliary write enable\n
INLINE_OUT_EN: u1 = 0,
/// OUT_EN_SEL [19:23]
/// Which data bit to use for inline OUT enable
OUT_EN_SEL: u5 = 0,
/// JMP_PIN [24:28]
/// The GPIO number to use as condition for JMP PIN. Unaffected by input mapping.
JMP_PIN: u5 = 0,
/// SIDE_PINDIR [29:29]
/// If 1, side-set data is asserted to pin directions, instead of pin values
SIDE_PINDIR: u1 = 0,
/// SIDE_EN [30:30]
/// If 1, the MSB of the Delay/Side-set instruction field is used as side-set enable, rather than a side-set data bit. This allows instructions to perform side-set optionally, rather than on every instruction, but the maximum possible side-set width is reduced from 5 to 4. Note that the value of PINCTRL_SIDESET_COUNT is inclusive of this enable bit.
SIDE_EN: u1 = 0,
/// EXEC_STALLED [31:31]
/// If 1, an instruction written to SMx_INSTR is stalled, and latched by the state machine. Will clear to 0 once this instruction completes.
EXEC_STALLED: u1 = 0,
};
/// Execution/behavioural settings for state machine 0
pub const SM0_EXECCTRL = Register(SM0_EXECCTRL_val).init(base_address + 0xcc);

/// SM0_CLKDIV
const SM0_CLKDIV_val = packed struct {
/// unused [0:7]
_unused0: u8 = 0,
/// FRAC [8:15]
/// Fractional part of clock divisor
FRAC: u8 = 0,
/// INT [16:31]
/// Effective frequency is sysclk/(int + frac/256).\n
INT: u16 = 1,
};
/// Clock divisor register for state machine 0\n
pub const SM0_CLKDIV = Register(SM0_CLKDIV_val).init(base_address + 0xc8);

/// INSTR_MEM31
const INSTR_MEM31_val = packed struct {
/// INSTR_MEM31 [0:15]
/// No description
INSTR_MEM31: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 31
pub const INSTR_MEM31 = Register(INSTR_MEM31_val).init(base_address + 0xc4);

/// INSTR_MEM30
const INSTR_MEM30_val = packed struct {
/// INSTR_MEM30 [0:15]
/// No description
INSTR_MEM30: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 30
pub const INSTR_MEM30 = Register(INSTR_MEM30_val).init(base_address + 0xc0);

/// INSTR_MEM29
const INSTR_MEM29_val = packed struct {
/// INSTR_MEM29 [0:15]
/// No description
INSTR_MEM29: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 29
pub const INSTR_MEM29 = Register(INSTR_MEM29_val).init(base_address + 0xbc);

/// INSTR_MEM28
const INSTR_MEM28_val = packed struct {
/// INSTR_MEM28 [0:15]
/// No description
INSTR_MEM28: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 28
pub const INSTR_MEM28 = Register(INSTR_MEM28_val).init(base_address + 0xb8);

/// INSTR_MEM27
const INSTR_MEM27_val = packed struct {
/// INSTR_MEM27 [0:15]
/// No description
INSTR_MEM27: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 27
pub const INSTR_MEM27 = Register(INSTR_MEM27_val).init(base_address + 0xb4);

/// INSTR_MEM26
const INSTR_MEM26_val = packed struct {
/// INSTR_MEM26 [0:15]
/// No description
INSTR_MEM26: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 26
pub const INSTR_MEM26 = Register(INSTR_MEM26_val).init(base_address + 0xb0);

/// INSTR_MEM25
const INSTR_MEM25_val = packed struct {
/// INSTR_MEM25 [0:15]
/// No description
INSTR_MEM25: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 25
pub const INSTR_MEM25 = Register(INSTR_MEM25_val).init(base_address + 0xac);

/// INSTR_MEM24
const INSTR_MEM24_val = packed struct {
/// INSTR_MEM24 [0:15]
/// No description
INSTR_MEM24: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 24
pub const INSTR_MEM24 = Register(INSTR_MEM24_val).init(base_address + 0xa8);

/// INSTR_MEM23
const INSTR_MEM23_val = packed struct {
/// INSTR_MEM23 [0:15]
/// No description
INSTR_MEM23: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 23
pub const INSTR_MEM23 = Register(INSTR_MEM23_val).init(base_address + 0xa4);

/// INSTR_MEM22
const INSTR_MEM22_val = packed struct {
/// INSTR_MEM22 [0:15]
/// No description
INSTR_MEM22: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 22
pub const INSTR_MEM22 = Register(INSTR_MEM22_val).init(base_address + 0xa0);

/// INSTR_MEM21
const INSTR_MEM21_val = packed struct {
/// INSTR_MEM21 [0:15]
/// No description
INSTR_MEM21: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 21
pub const INSTR_MEM21 = Register(INSTR_MEM21_val).init(base_address + 0x9c);

/// INSTR_MEM20
const INSTR_MEM20_val = packed struct {
/// INSTR_MEM20 [0:15]
/// No description
INSTR_MEM20: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 20
pub const INSTR_MEM20 = Register(INSTR_MEM20_val).init(base_address + 0x98);

/// INSTR_MEM19
const INSTR_MEM19_val = packed struct {
/// INSTR_MEM19 [0:15]
/// No description
INSTR_MEM19: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 19
pub const INSTR_MEM19 = Register(INSTR_MEM19_val).init(base_address + 0x94);

/// INSTR_MEM18
const INSTR_MEM18_val = packed struct {
/// INSTR_MEM18 [0:15]
/// No description
INSTR_MEM18: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 18
pub const INSTR_MEM18 = Register(INSTR_MEM18_val).init(base_address + 0x90);

/// INSTR_MEM17
const INSTR_MEM17_val = packed struct {
/// INSTR_MEM17 [0:15]
/// No description
INSTR_MEM17: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 17
pub const INSTR_MEM17 = Register(INSTR_MEM17_val).init(base_address + 0x8c);

/// INSTR_MEM16
const INSTR_MEM16_val = packed struct {
/// INSTR_MEM16 [0:15]
/// No description
INSTR_MEM16: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 16
pub const INSTR_MEM16 = Register(INSTR_MEM16_val).init(base_address + 0x88);

/// INSTR_MEM15
const INSTR_MEM15_val = packed struct {
/// INSTR_MEM15 [0:15]
/// No description
INSTR_MEM15: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 15
pub const INSTR_MEM15 = Register(INSTR_MEM15_val).init(base_address + 0x84);

/// INSTR_MEM14
const INSTR_MEM14_val = packed struct {
/// INSTR_MEM14 [0:15]
/// No description
INSTR_MEM14: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 14
pub const INSTR_MEM14 = Register(INSTR_MEM14_val).init(base_address + 0x80);

/// INSTR_MEM13
const INSTR_MEM13_val = packed struct {
/// INSTR_MEM13 [0:15]
/// No description
INSTR_MEM13: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 13
pub const INSTR_MEM13 = Register(INSTR_MEM13_val).init(base_address + 0x7c);

/// INSTR_MEM12
const INSTR_MEM12_val = packed struct {
/// INSTR_MEM12 [0:15]
/// No description
INSTR_MEM12: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 12
pub const INSTR_MEM12 = Register(INSTR_MEM12_val).init(base_address + 0x78);

/// INSTR_MEM11
const INSTR_MEM11_val = packed struct {
/// INSTR_MEM11 [0:15]
/// No description
INSTR_MEM11: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 11
pub const INSTR_MEM11 = Register(INSTR_MEM11_val).init(base_address + 0x74);

/// INSTR_MEM10
const INSTR_MEM10_val = packed struct {
/// INSTR_MEM10 [0:15]
/// No description
INSTR_MEM10: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 10
pub const INSTR_MEM10 = Register(INSTR_MEM10_val).init(base_address + 0x70);

/// INSTR_MEM9
const INSTR_MEM9_val = packed struct {
/// INSTR_MEM9 [0:15]
/// No description
INSTR_MEM9: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 9
pub const INSTR_MEM9 = Register(INSTR_MEM9_val).init(base_address + 0x6c);

/// INSTR_MEM8
const INSTR_MEM8_val = packed struct {
/// INSTR_MEM8 [0:15]
/// No description
INSTR_MEM8: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 8
pub const INSTR_MEM8 = Register(INSTR_MEM8_val).init(base_address + 0x68);

/// INSTR_MEM7
const INSTR_MEM7_val = packed struct {
/// INSTR_MEM7 [0:15]
/// No description
INSTR_MEM7: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 7
pub const INSTR_MEM7 = Register(INSTR_MEM7_val).init(base_address + 0x64);

/// INSTR_MEM6
const INSTR_MEM6_val = packed struct {
/// INSTR_MEM6 [0:15]
/// No description
INSTR_MEM6: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 6
pub const INSTR_MEM6 = Register(INSTR_MEM6_val).init(base_address + 0x60);

/// INSTR_MEM5
const INSTR_MEM5_val = packed struct {
/// INSTR_MEM5 [0:15]
/// No description
INSTR_MEM5: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 5
pub const INSTR_MEM5 = Register(INSTR_MEM5_val).init(base_address + 0x5c);

/// INSTR_MEM4
const INSTR_MEM4_val = packed struct {
/// INSTR_MEM4 [0:15]
/// No description
INSTR_MEM4: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 4
pub const INSTR_MEM4 = Register(INSTR_MEM4_val).init(base_address + 0x58);

/// INSTR_MEM3
const INSTR_MEM3_val = packed struct {
/// INSTR_MEM3 [0:15]
/// No description
INSTR_MEM3: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 3
pub const INSTR_MEM3 = Register(INSTR_MEM3_val).init(base_address + 0x54);

/// INSTR_MEM2
const INSTR_MEM2_val = packed struct {
/// INSTR_MEM2 [0:15]
/// No description
INSTR_MEM2: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 2
pub const INSTR_MEM2 = Register(INSTR_MEM2_val).init(base_address + 0x50);

/// INSTR_MEM1
const INSTR_MEM1_val = packed struct {
/// INSTR_MEM1 [0:15]
/// No description
INSTR_MEM1: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 1
pub const INSTR_MEM1 = Register(INSTR_MEM1_val).init(base_address + 0x4c);

/// INSTR_MEM0
const INSTR_MEM0_val = packed struct {
/// INSTR_MEM0 [0:15]
/// No description
INSTR_MEM0: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 0
pub const INSTR_MEM0 = Register(INSTR_MEM0_val).init(base_address + 0x48);

/// DBG_CFGINFO
const DBG_CFGINFO_val = packed struct {
/// FIFO_DEPTH [0:5]
/// The depth of the state machine TX/RX FIFOs, measured in words.\n
FIFO_DEPTH: u6 = 0,
/// unused [6:7]
_unused6: u2 = 0,
/// SM_COUNT [8:11]
/// The number of state machines this PIO instance is equipped with.
SM_COUNT: u4 = 0,
/// unused [12:15]
_unused12: u4 = 0,
/// IMEM_SIZE [16:21]
/// The size of the instruction memory, measured in units of one instruction
IMEM_SIZE: u6 = 0,
/// unused [22:31]
_unused22: u2 = 0,
_unused24: u8 = 0,
};
/// The PIO hardware has some free parameters that may vary between chip products.\n
pub const DBG_CFGINFO = Register(DBG_CFGINFO_val).init(base_address + 0x44);

/// DBG_PADOE
const DBG_PADOE_val = packed struct {
DBG_PADOE_0: u8 = 0,
DBG_PADOE_1: u8 = 0,
DBG_PADOE_2: u8 = 0,
DBG_PADOE_3: u8 = 0,
};
/// Read to sample the pad output enables (direction) PIO is currently driving to the GPIOs.
pub const DBG_PADOE = Register(DBG_PADOE_val).init(base_address + 0x40);

/// DBG_PADOUT
const DBG_PADOUT_val = packed struct {
DBG_PADOUT_0: u8 = 0,
DBG_PADOUT_1: u8 = 0,
DBG_PADOUT_2: u8 = 0,
DBG_PADOUT_3: u8 = 0,
};
/// Read to sample the pad output values PIO is currently driving to the GPIOs.
pub const DBG_PADOUT = Register(DBG_PADOUT_val).init(base_address + 0x3c);

/// INPUT_SYNC_BYPASS
const INPUT_SYNC_BYPASS_val = packed struct {
INPUT_SYNC_BYPASS_0: u8 = 0,
INPUT_SYNC_BYPASS_1: u8 = 0,
INPUT_SYNC_BYPASS_2: u8 = 0,
INPUT_SYNC_BYPASS_3: u8 = 0,
};
/// There is a 2-flipflop synchronizer on each GPIO input, which protects PIO logic from metastabilities. This increases input delay, and for fast synchronous IO (e.g. SPI) these synchronizers may need to be bypassed. Each bit in this register corresponds to one GPIO.\n
pub const INPUT_SYNC_BYPASS = Register(INPUT_SYNC_BYPASS_val).init(base_address + 0x38);

/// IRQ_FORCE
const IRQ_FORCE_val = packed struct {
/// IRQ_FORCE [0:7]
/// No description
IRQ_FORCE: u8 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Writing a 1 to each of these bits will forcibly assert the corresponding IRQ. Note this is different to the INTF register: writing here affects PIO internal state. INTF just asserts the processor-facing IRQ signal for testing ISRs, and is not visible to the state machines.
pub const IRQ_FORCE = Register(IRQ_FORCE_val).init(base_address + 0x34);

/// IRQ
const IRQ_val = packed struct {
/// IRQ [0:7]
/// No description
IRQ: u8 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// State machine IRQ flags register. Write 1 to clear. There are 8 state machine IRQ flags, which can be set, cleared, and waited on by the state machines. There's no fixed association between flags and state machines -- any state machine can use any flag.\n\n
pub const IRQ = Register(IRQ_val).init(base_address + 0x30);

/// RXF3
const RXF3_val = packed struct {
RXF3_0: u8 = 0,
RXF3_1: u8 = 0,
RXF3_2: u8 = 0,
RXF3_3: u8 = 0,
};
/// Direct read access to the RX FIFO for this state machine. Each read pops one word from the FIFO. Attempting to read from an empty FIFO has no effect on the FIFO state, and sets the sticky FDEBUG_RXUNDER error flag for this FIFO. The data returned to the system on a read from an empty FIFO is undefined.
pub const RXF3 = Register(RXF3_val).init(base_address + 0x2c);

/// RXF2
const RXF2_val = packed struct {
RXF2_0: u8 = 0,
RXF2_1: u8 = 0,
RXF2_2: u8 = 0,
RXF2_3: u8 = 0,
};
/// Direct read access to the RX FIFO for this state machine. Each read pops one word from the FIFO. Attempting to read from an empty FIFO has no effect on the FIFO state, and sets the sticky FDEBUG_RXUNDER error flag for this FIFO. The data returned to the system on a read from an empty FIFO is undefined.
pub const RXF2 = Register(RXF2_val).init(base_address + 0x28);

/// RXF1
const RXF1_val = packed struct {
RXF1_0: u8 = 0,
RXF1_1: u8 = 0,
RXF1_2: u8 = 0,
RXF1_3: u8 = 0,
};
/// Direct read access to the RX FIFO for this state machine. Each read pops one word from the FIFO. Attempting to read from an empty FIFO has no effect on the FIFO state, and sets the sticky FDEBUG_RXUNDER error flag for this FIFO. The data returned to the system on a read from an empty FIFO is undefined.
pub const RXF1 = Register(RXF1_val).init(base_address + 0x24);

/// RXF0
const RXF0_val = packed struct {
RXF0_0: u8 = 0,
RXF0_1: u8 = 0,
RXF0_2: u8 = 0,
RXF0_3: u8 = 0,
};
/// Direct read access to the RX FIFO for this state machine. Each read pops one word from the FIFO. Attempting to read from an empty FIFO has no effect on the FIFO state, and sets the sticky FDEBUG_RXUNDER error flag for this FIFO. The data returned to the system on a read from an empty FIFO is undefined.
pub const RXF0 = Register(RXF0_val).init(base_address + 0x20);

/// TXF3
const TXF3_val = packed struct {
TXF3_0: u8 = 0,
TXF3_1: u8 = 0,
TXF3_2: u8 = 0,
TXF3_3: u8 = 0,
};
/// Direct write access to the TX FIFO for this state machine. Each write pushes one word to the FIFO. Attempting to write to a full FIFO has no effect on the FIFO state or contents, and sets the sticky FDEBUG_TXOVER error flag for this FIFO.
pub const TXF3 = Register(TXF3_val).init(base_address + 0x1c);

/// TXF2
const TXF2_val = packed struct {
TXF2_0: u8 = 0,
TXF2_1: u8 = 0,
TXF2_2: u8 = 0,
TXF2_3: u8 = 0,
};
/// Direct write access to the TX FIFO for this state machine. Each write pushes one word to the FIFO. Attempting to write to a full FIFO has no effect on the FIFO state or contents, and sets the sticky FDEBUG_TXOVER error flag for this FIFO.
pub const TXF2 = Register(TXF2_val).init(base_address + 0x18);

/// TXF1
const TXF1_val = packed struct {
TXF1_0: u8 = 0,
TXF1_1: u8 = 0,
TXF1_2: u8 = 0,
TXF1_3: u8 = 0,
};
/// Direct write access to the TX FIFO for this state machine. Each write pushes one word to the FIFO. Attempting to write to a full FIFO has no effect on the FIFO state or contents, and sets the sticky FDEBUG_TXOVER error flag for this FIFO.
pub const TXF1 = Register(TXF1_val).init(base_address + 0x14);

/// TXF0
const TXF0_val = packed struct {
TXF0_0: u8 = 0,
TXF0_1: u8 = 0,
TXF0_2: u8 = 0,
TXF0_3: u8 = 0,
};
/// Direct write access to the TX FIFO for this state machine. Each write pushes one word to the FIFO. Attempting to write to a full FIFO has no effect on the FIFO state or contents, and sets the sticky FDEBUG_TXOVER error flag for this FIFO.
pub const TXF0 = Register(TXF0_val).init(base_address + 0x10);

/// FLEVEL
const FLEVEL_val = packed struct {
/// TX0 [0:3]
/// No description
TX0: u4 = 0,
/// RX0 [4:7]
/// No description
RX0: u4 = 0,
/// TX1 [8:11]
/// No description
TX1: u4 = 0,
/// RX1 [12:15]
/// No description
RX1: u4 = 0,
/// TX2 [16:19]
/// No description
TX2: u4 = 0,
/// RX2 [20:23]
/// No description
RX2: u4 = 0,
/// TX3 [24:27]
/// No description
TX3: u4 = 0,
/// RX3 [28:31]
/// No description
RX3: u4 = 0,
};
/// FIFO levels
pub const FLEVEL = Register(FLEVEL_val).init(base_address + 0xc);

/// FDEBUG
const FDEBUG_val = packed struct {
/// RXSTALL [0:3]
/// State machine has stalled on full RX FIFO during a blocking PUSH, or an IN with autopush enabled. This flag is also set when a nonblocking PUSH to a full FIFO took place, in which case the state machine has dropped data. Write 1 to clear.
RXSTALL: u4 = 0,
/// unused [4:7]
_unused4: u4 = 0,
/// RXUNDER [8:11]
/// RX FIFO underflow (i.e. read-on-empty by the system) has occurred. Write 1 to clear. Note that read-on-empty does not perturb the state of the FIFO in any way, but the data returned by reading from an empty FIFO is undefined, so this flag generally only becomes set due to some kind of software error.
RXUNDER: u4 = 0,
/// unused [12:15]
_unused12: u4 = 0,
/// TXOVER [16:19]
/// TX FIFO overflow (i.e. write-on-full by the system) has occurred. Write 1 to clear. Note that write-on-full does not alter the state or contents of the FIFO in any way, but the data that the system attempted to write is dropped, so if this flag is set, your software has quite likely dropped some data on the floor.
TXOVER: u4 = 0,
/// unused [20:23]
_unused20: u4 = 0,
/// TXSTALL [24:27]
/// State machine has stalled on empty TX FIFO during a blocking PULL, or an OUT with autopull enabled. Write 1 to clear.
TXSTALL: u4 = 0,
/// unused [28:31]
_unused28: u4 = 0,
};
/// FIFO debug register
pub const FDEBUG = Register(FDEBUG_val).init(base_address + 0x8);

/// FSTAT
const FSTAT_val = packed struct {
/// RXFULL [0:3]
/// State machine RX FIFO is full
RXFULL: u4 = 0,
/// unused [4:7]
_unused4: u4 = 0,
/// RXEMPTY [8:11]
/// State machine RX FIFO is empty
RXEMPTY: u4 = 15,
/// unused [12:15]
_unused12: u4 = 0,
/// TXFULL [16:19]
/// State machine TX FIFO is full
TXFULL: u4 = 0,
/// unused [20:23]
_unused20: u4 = 0,
/// TXEMPTY [24:27]
/// State machine TX FIFO is empty
TXEMPTY: u4 = 15,
/// unused [28:31]
_unused28: u4 = 0,
};
/// FIFO status register
pub const FSTAT = Register(FSTAT_val).init(base_address + 0x4);

/// CTRL
const CTRL_val = packed struct {
/// SM_ENABLE [0:3]
/// Enable/disable each of the four state machines by writing 1/0 to each of these four bits. When disabled, a state machine will cease executing instructions, except those written directly to SMx_INSTR by the system. Multiple bits can be set/cleared at once to run/halt multiple state machines simultaneously.
SM_ENABLE: u4 = 0,
/// SM_RESTART [4:7]
/// Write 1 to instantly clear internal SM state which may be otherwise difficult to access and will affect future execution.\n\n
SM_RESTART: u4 = 0,
/// CLKDIV_RESTART [8:11]
/// Restart a state machine's clock divider from an initial phase of 0. Clock dividers are free-running, so once started, their output (including fractional jitter) is completely determined by the integer/fractional divisor configured in SMx_CLKDIV. This means that, if multiple clock dividers with the same divisor are restarted simultaneously, by writing multiple 1 bits to this field, the execution clocks of those state machines will run in precise lockstep.\n\n
CLKDIV_RESTART: u4 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// PIO control register
pub const CTRL = Register(CTRL_val).init(base_address + 0x0);
};

/// Programmable IO block
pub const PIO1 = struct {

const base_address = 0x50300000;
/// IRQ1_INTS
const IRQ1_INTS_val = packed struct {
/// SM0_RXNEMPTY [0:0]
/// No description
SM0_RXNEMPTY: u1 = 0,
/// SM1_RXNEMPTY [1:1]
/// No description
SM1_RXNEMPTY: u1 = 0,
/// SM2_RXNEMPTY [2:2]
/// No description
SM2_RXNEMPTY: u1 = 0,
/// SM3_RXNEMPTY [3:3]
/// No description
SM3_RXNEMPTY: u1 = 0,
/// SM0_TXNFULL [4:4]
/// No description
SM0_TXNFULL: u1 = 0,
/// SM1_TXNFULL [5:5]
/// No description
SM1_TXNFULL: u1 = 0,
/// SM2_TXNFULL [6:6]
/// No description
SM2_TXNFULL: u1 = 0,
/// SM3_TXNFULL [7:7]
/// No description
SM3_TXNFULL: u1 = 0,
/// SM0 [8:8]
/// No description
SM0: u1 = 0,
/// SM1 [9:9]
/// No description
SM1: u1 = 0,
/// SM2 [10:10]
/// No description
SM2: u1 = 0,
/// SM3 [11:11]
/// No description
SM3: u1 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Interrupt status after masking &amp; forcing for irq1
pub const IRQ1_INTS = Register(IRQ1_INTS_val).init(base_address + 0x140);

/// IRQ1_INTF
const IRQ1_INTF_val = packed struct {
/// SM0_RXNEMPTY [0:0]
/// No description
SM0_RXNEMPTY: u1 = 0,
/// SM1_RXNEMPTY [1:1]
/// No description
SM1_RXNEMPTY: u1 = 0,
/// SM2_RXNEMPTY [2:2]
/// No description
SM2_RXNEMPTY: u1 = 0,
/// SM3_RXNEMPTY [3:3]
/// No description
SM3_RXNEMPTY: u1 = 0,
/// SM0_TXNFULL [4:4]
/// No description
SM0_TXNFULL: u1 = 0,
/// SM1_TXNFULL [5:5]
/// No description
SM1_TXNFULL: u1 = 0,
/// SM2_TXNFULL [6:6]
/// No description
SM2_TXNFULL: u1 = 0,
/// SM3_TXNFULL [7:7]
/// No description
SM3_TXNFULL: u1 = 0,
/// SM0 [8:8]
/// No description
SM0: u1 = 0,
/// SM1 [9:9]
/// No description
SM1: u1 = 0,
/// SM2 [10:10]
/// No description
SM2: u1 = 0,
/// SM3 [11:11]
/// No description
SM3: u1 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Interrupt Force for irq1
pub const IRQ1_INTF = Register(IRQ1_INTF_val).init(base_address + 0x13c);

/// IRQ1_INTE
const IRQ1_INTE_val = packed struct {
/// SM0_RXNEMPTY [0:0]
/// No description
SM0_RXNEMPTY: u1 = 0,
/// SM1_RXNEMPTY [1:1]
/// No description
SM1_RXNEMPTY: u1 = 0,
/// SM2_RXNEMPTY [2:2]
/// No description
SM2_RXNEMPTY: u1 = 0,
/// SM3_RXNEMPTY [3:3]
/// No description
SM3_RXNEMPTY: u1 = 0,
/// SM0_TXNFULL [4:4]
/// No description
SM0_TXNFULL: u1 = 0,
/// SM1_TXNFULL [5:5]
/// No description
SM1_TXNFULL: u1 = 0,
/// SM2_TXNFULL [6:6]
/// No description
SM2_TXNFULL: u1 = 0,
/// SM3_TXNFULL [7:7]
/// No description
SM3_TXNFULL: u1 = 0,
/// SM0 [8:8]
/// No description
SM0: u1 = 0,
/// SM1 [9:9]
/// No description
SM1: u1 = 0,
/// SM2 [10:10]
/// No description
SM2: u1 = 0,
/// SM3 [11:11]
/// No description
SM3: u1 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Interrupt Enable for irq1
pub const IRQ1_INTE = Register(IRQ1_INTE_val).init(base_address + 0x138);

/// IRQ0_INTS
const IRQ0_INTS_val = packed struct {
/// SM0_RXNEMPTY [0:0]
/// No description
SM0_RXNEMPTY: u1 = 0,
/// SM1_RXNEMPTY [1:1]
/// No description
SM1_RXNEMPTY: u1 = 0,
/// SM2_RXNEMPTY [2:2]
/// No description
SM2_RXNEMPTY: u1 = 0,
/// SM3_RXNEMPTY [3:3]
/// No description
SM3_RXNEMPTY: u1 = 0,
/// SM0_TXNFULL [4:4]
/// No description
SM0_TXNFULL: u1 = 0,
/// SM1_TXNFULL [5:5]
/// No description
SM1_TXNFULL: u1 = 0,
/// SM2_TXNFULL [6:6]
/// No description
SM2_TXNFULL: u1 = 0,
/// SM3_TXNFULL [7:7]
/// No description
SM3_TXNFULL: u1 = 0,
/// SM0 [8:8]
/// No description
SM0: u1 = 0,
/// SM1 [9:9]
/// No description
SM1: u1 = 0,
/// SM2 [10:10]
/// No description
SM2: u1 = 0,
/// SM3 [11:11]
/// No description
SM3: u1 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Interrupt status after masking &amp; forcing for irq0
pub const IRQ0_INTS = Register(IRQ0_INTS_val).init(base_address + 0x134);

/// IRQ0_INTF
const IRQ0_INTF_val = packed struct {
/// SM0_RXNEMPTY [0:0]
/// No description
SM0_RXNEMPTY: u1 = 0,
/// SM1_RXNEMPTY [1:1]
/// No description
SM1_RXNEMPTY: u1 = 0,
/// SM2_RXNEMPTY [2:2]
/// No description
SM2_RXNEMPTY: u1 = 0,
/// SM3_RXNEMPTY [3:3]
/// No description
SM3_RXNEMPTY: u1 = 0,
/// SM0_TXNFULL [4:4]
/// No description
SM0_TXNFULL: u1 = 0,
/// SM1_TXNFULL [5:5]
/// No description
SM1_TXNFULL: u1 = 0,
/// SM2_TXNFULL [6:6]
/// No description
SM2_TXNFULL: u1 = 0,
/// SM3_TXNFULL [7:7]
/// No description
SM3_TXNFULL: u1 = 0,
/// SM0 [8:8]
/// No description
SM0: u1 = 0,
/// SM1 [9:9]
/// No description
SM1: u1 = 0,
/// SM2 [10:10]
/// No description
SM2: u1 = 0,
/// SM3 [11:11]
/// No description
SM3: u1 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Interrupt Force for irq0
pub const IRQ0_INTF = Register(IRQ0_INTF_val).init(base_address + 0x130);

/// IRQ0_INTE
const IRQ0_INTE_val = packed struct {
/// SM0_RXNEMPTY [0:0]
/// No description
SM0_RXNEMPTY: u1 = 0,
/// SM1_RXNEMPTY [1:1]
/// No description
SM1_RXNEMPTY: u1 = 0,
/// SM2_RXNEMPTY [2:2]
/// No description
SM2_RXNEMPTY: u1 = 0,
/// SM3_RXNEMPTY [3:3]
/// No description
SM3_RXNEMPTY: u1 = 0,
/// SM0_TXNFULL [4:4]
/// No description
SM0_TXNFULL: u1 = 0,
/// SM1_TXNFULL [5:5]
/// No description
SM1_TXNFULL: u1 = 0,
/// SM2_TXNFULL [6:6]
/// No description
SM2_TXNFULL: u1 = 0,
/// SM3_TXNFULL [7:7]
/// No description
SM3_TXNFULL: u1 = 0,
/// SM0 [8:8]
/// No description
SM0: u1 = 0,
/// SM1 [9:9]
/// No description
SM1: u1 = 0,
/// SM2 [10:10]
/// No description
SM2: u1 = 0,
/// SM3 [11:11]
/// No description
SM3: u1 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Interrupt Enable for irq0
pub const IRQ0_INTE = Register(IRQ0_INTE_val).init(base_address + 0x12c);

/// INTR
const INTR_val = packed struct {
/// SM0_RXNEMPTY [0:0]
/// No description
SM0_RXNEMPTY: u1 = 0,
/// SM1_RXNEMPTY [1:1]
/// No description
SM1_RXNEMPTY: u1 = 0,
/// SM2_RXNEMPTY [2:2]
/// No description
SM2_RXNEMPTY: u1 = 0,
/// SM3_RXNEMPTY [3:3]
/// No description
SM3_RXNEMPTY: u1 = 0,
/// SM0_TXNFULL [4:4]
/// No description
SM0_TXNFULL: u1 = 0,
/// SM1_TXNFULL [5:5]
/// No description
SM1_TXNFULL: u1 = 0,
/// SM2_TXNFULL [6:6]
/// No description
SM2_TXNFULL: u1 = 0,
/// SM3_TXNFULL [7:7]
/// No description
SM3_TXNFULL: u1 = 0,
/// SM0 [8:8]
/// No description
SM0: u1 = 0,
/// SM1 [9:9]
/// No description
SM1: u1 = 0,
/// SM2 [10:10]
/// No description
SM2: u1 = 0,
/// SM3 [11:11]
/// No description
SM3: u1 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Raw Interrupts
pub const INTR = Register(INTR_val).init(base_address + 0x128);

/// SM3_PINCTRL
const SM3_PINCTRL_val = packed struct {
/// OUT_BASE [0:4]
/// The lowest-numbered pin that will be affected by an OUT PINS, OUT PINDIRS or MOV PINS instruction. The data written to this pin will always be the least-significant bit of the OUT or MOV data.
OUT_BASE: u5 = 0,
/// SET_BASE [5:9]
/// The lowest-numbered pin that will be affected by a SET PINS or SET PINDIRS instruction. The data written to this pin is the least-significant bit of the SET data.
SET_BASE: u5 = 0,
/// SIDESET_BASE [10:14]
/// The lowest-numbered pin that will be affected by a side-set operation. The MSBs of an instruction's side-set/delay field (up to 5, determined by SIDESET_COUNT) are used for side-set data, with the remaining LSBs used for delay. The least-significant bit of the side-set portion is the bit written to this pin, with more-significant bits written to higher-numbered pins.
SIDESET_BASE: u5 = 0,
/// IN_BASE [15:19]
/// The pin which is mapped to the least-significant bit of a state machine's IN data bus. Higher-numbered pins are mapped to consecutively more-significant data bits, with a modulo of 32 applied to pin number.
IN_BASE: u5 = 0,
/// OUT_COUNT [20:25]
/// The number of pins asserted by an OUT PINS, OUT PINDIRS or MOV PINS instruction. In the range 0 to 32 inclusive.
OUT_COUNT: u6 = 0,
/// SET_COUNT [26:28]
/// The number of pins asserted by a SET. In the range 0 to 5 inclusive.
SET_COUNT: u3 = 5,
/// SIDESET_COUNT [29:31]
/// The number of MSBs of the Delay/Side-set instruction field which are used for side-set. Inclusive of the enable bit, if present. Minimum of 0 (all delay bits, no side-set) and maximum of 5 (all side-set, no delay).
SIDESET_COUNT: u3 = 0,
};
/// State machine pin control
pub const SM3_PINCTRL = Register(SM3_PINCTRL_val).init(base_address + 0x124);

/// SM3_INSTR
const SM3_INSTR_val = packed struct {
/// SM3_INSTR [0:15]
/// No description
SM3_INSTR: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Read to see the instruction currently addressed by state machine 3's program counter\n
pub const SM3_INSTR = Register(SM3_INSTR_val).init(base_address + 0x120);

/// SM3_ADDR
const SM3_ADDR_val = packed struct {
/// SM3_ADDR [0:4]
/// No description
SM3_ADDR: u5 = 0,
/// unused [5:31]
_unused5: u3 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Current instruction address of state machine 3
pub const SM3_ADDR = Register(SM3_ADDR_val).init(base_address + 0x11c);

/// SM3_SHIFTCTRL
const SM3_SHIFTCTRL_val = packed struct {
/// unused [0:15]
_unused0: u8 = 0,
_unused8: u8 = 0,
/// AUTOPUSH [16:16]
/// Push automatically when the input shift register is filled, i.e. on an IN instruction which causes the input shift counter to reach or exceed PUSH_THRESH.
AUTOPUSH: u1 = 0,
/// AUTOPULL [17:17]
/// Pull automatically when the output shift register is emptied, i.e. on or following an OUT instruction which causes the output shift counter to reach or exceed PULL_THRESH.
AUTOPULL: u1 = 0,
/// IN_SHIFTDIR [18:18]
/// 1 = shift input shift register to right (data enters from left). 0 = to left.
IN_SHIFTDIR: u1 = 1,
/// OUT_SHIFTDIR [19:19]
/// 1 = shift out of output shift register to right. 0 = to left.
OUT_SHIFTDIR: u1 = 1,
/// PUSH_THRESH [20:24]
/// Number of bits shifted into ISR before autopush, or conditional push (PUSH IFFULL), will take place.\n
PUSH_THRESH: u5 = 0,
/// PULL_THRESH [25:29]
/// Number of bits shifted out of OSR before autopull, or conditional pull (PULL IFEMPTY), will take place.\n
PULL_THRESH: u5 = 0,
/// FJOIN_TX [30:30]
/// When 1, TX FIFO steals the RX FIFO's storage, and becomes twice as deep.\n
FJOIN_TX: u1 = 0,
/// FJOIN_RX [31:31]
/// When 1, RX FIFO steals the TX FIFO's storage, and becomes twice as deep.\n
FJOIN_RX: u1 = 0,
};
/// Control behaviour of the input/output shift registers for state machine 3
pub const SM3_SHIFTCTRL = Register(SM3_SHIFTCTRL_val).init(base_address + 0x118);

/// SM3_EXECCTRL
const SM3_EXECCTRL_val = packed struct {
/// STATUS_N [0:3]
/// Comparison level for the MOV x, STATUS instruction
STATUS_N: u4 = 0,
/// STATUS_SEL [4:4]
/// Comparison used for the MOV x, STATUS instruction.
STATUS_SEL: u1 = 0,
/// unused [5:6]
_unused5: u2 = 0,
/// WRAP_BOTTOM [7:11]
/// After reaching wrap_top, execution is wrapped to this address.
WRAP_BOTTOM: u5 = 0,
/// WRAP_TOP [12:16]
/// After reaching this address, execution is wrapped to wrap_bottom.\n
WRAP_TOP: u5 = 31,
/// OUT_STICKY [17:17]
/// Continuously assert the most recent OUT/SET to the pins
OUT_STICKY: u1 = 0,
/// INLINE_OUT_EN [18:18]
/// If 1, use a bit of OUT data as an auxiliary write enable\n
INLINE_OUT_EN: u1 = 0,
/// OUT_EN_SEL [19:23]
/// Which data bit to use for inline OUT enable
OUT_EN_SEL: u5 = 0,
/// JMP_PIN [24:28]
/// The GPIO number to use as condition for JMP PIN. Unaffected by input mapping.
JMP_PIN: u5 = 0,
/// SIDE_PINDIR [29:29]
/// If 1, side-set data is asserted to pin directions, instead of pin values
SIDE_PINDIR: u1 = 0,
/// SIDE_EN [30:30]
/// If 1, the MSB of the Delay/Side-set instruction field is used as side-set enable, rather than a side-set data bit. This allows instructions to perform side-set optionally, rather than on every instruction, but the maximum possible side-set width is reduced from 5 to 4. Note that the value of PINCTRL_SIDESET_COUNT is inclusive of this enable bit.
SIDE_EN: u1 = 0,
/// EXEC_STALLED [31:31]
/// If 1, an instruction written to SMx_INSTR is stalled, and latched by the state machine. Will clear to 0 once this instruction completes.
EXEC_STALLED: u1 = 0,
};
/// Execution/behavioural settings for state machine 3
pub const SM3_EXECCTRL = Register(SM3_EXECCTRL_val).init(base_address + 0x114);

/// SM3_CLKDIV
const SM3_CLKDIV_val = packed struct {
/// unused [0:7]
_unused0: u8 = 0,
/// FRAC [8:15]
/// Fractional part of clock divisor
FRAC: u8 = 0,
/// INT [16:31]
/// Effective frequency is sysclk/(int + frac/256).\n
INT: u16 = 1,
};
/// Clock divisor register for state machine 3\n
pub const SM3_CLKDIV = Register(SM3_CLKDIV_val).init(base_address + 0x110);

/// SM2_PINCTRL
const SM2_PINCTRL_val = packed struct {
/// OUT_BASE [0:4]
/// The lowest-numbered pin that will be affected by an OUT PINS, OUT PINDIRS or MOV PINS instruction. The data written to this pin will always be the least-significant bit of the OUT or MOV data.
OUT_BASE: u5 = 0,
/// SET_BASE [5:9]
/// The lowest-numbered pin that will be affected by a SET PINS or SET PINDIRS instruction. The data written to this pin is the least-significant bit of the SET data.
SET_BASE: u5 = 0,
/// SIDESET_BASE [10:14]
/// The lowest-numbered pin that will be affected by a side-set operation. The MSBs of an instruction's side-set/delay field (up to 5, determined by SIDESET_COUNT) are used for side-set data, with the remaining LSBs used for delay. The least-significant bit of the side-set portion is the bit written to this pin, with more-significant bits written to higher-numbered pins.
SIDESET_BASE: u5 = 0,
/// IN_BASE [15:19]
/// The pin which is mapped to the least-significant bit of a state machine's IN data bus. Higher-numbered pins are mapped to consecutively more-significant data bits, with a modulo of 32 applied to pin number.
IN_BASE: u5 = 0,
/// OUT_COUNT [20:25]
/// The number of pins asserted by an OUT PINS, OUT PINDIRS or MOV PINS instruction. In the range 0 to 32 inclusive.
OUT_COUNT: u6 = 0,
/// SET_COUNT [26:28]
/// The number of pins asserted by a SET. In the range 0 to 5 inclusive.
SET_COUNT: u3 = 5,
/// SIDESET_COUNT [29:31]
/// The number of MSBs of the Delay/Side-set instruction field which are used for side-set. Inclusive of the enable bit, if present. Minimum of 0 (all delay bits, no side-set) and maximum of 5 (all side-set, no delay).
SIDESET_COUNT: u3 = 0,
};
/// State machine pin control
pub const SM2_PINCTRL = Register(SM2_PINCTRL_val).init(base_address + 0x10c);

/// SM2_INSTR
const SM2_INSTR_val = packed struct {
/// SM2_INSTR [0:15]
/// No description
SM2_INSTR: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Read to see the instruction currently addressed by state machine 2's program counter\n
pub const SM2_INSTR = Register(SM2_INSTR_val).init(base_address + 0x108);

/// SM2_ADDR
const SM2_ADDR_val = packed struct {
/// SM2_ADDR [0:4]
/// No description
SM2_ADDR: u5 = 0,
/// unused [5:31]
_unused5: u3 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Current instruction address of state machine 2
pub const SM2_ADDR = Register(SM2_ADDR_val).init(base_address + 0x104);

/// SM2_SHIFTCTRL
const SM2_SHIFTCTRL_val = packed struct {
/// unused [0:15]
_unused0: u8 = 0,
_unused8: u8 = 0,
/// AUTOPUSH [16:16]
/// Push automatically when the input shift register is filled, i.e. on an IN instruction which causes the input shift counter to reach or exceed PUSH_THRESH.
AUTOPUSH: u1 = 0,
/// AUTOPULL [17:17]
/// Pull automatically when the output shift register is emptied, i.e. on or following an OUT instruction which causes the output shift counter to reach or exceed PULL_THRESH.
AUTOPULL: u1 = 0,
/// IN_SHIFTDIR [18:18]
/// 1 = shift input shift register to right (data enters from left). 0 = to left.
IN_SHIFTDIR: u1 = 1,
/// OUT_SHIFTDIR [19:19]
/// 1 = shift out of output shift register to right. 0 = to left.
OUT_SHIFTDIR: u1 = 1,
/// PUSH_THRESH [20:24]
/// Number of bits shifted into ISR before autopush, or conditional push (PUSH IFFULL), will take place.\n
PUSH_THRESH: u5 = 0,
/// PULL_THRESH [25:29]
/// Number of bits shifted out of OSR before autopull, or conditional pull (PULL IFEMPTY), will take place.\n
PULL_THRESH: u5 = 0,
/// FJOIN_TX [30:30]
/// When 1, TX FIFO steals the RX FIFO's storage, and becomes twice as deep.\n
FJOIN_TX: u1 = 0,
/// FJOIN_RX [31:31]
/// When 1, RX FIFO steals the TX FIFO's storage, and becomes twice as deep.\n
FJOIN_RX: u1 = 0,
};
/// Control behaviour of the input/output shift registers for state machine 2
pub const SM2_SHIFTCTRL = Register(SM2_SHIFTCTRL_val).init(base_address + 0x100);

/// SM2_EXECCTRL
const SM2_EXECCTRL_val = packed struct {
/// STATUS_N [0:3]
/// Comparison level for the MOV x, STATUS instruction
STATUS_N: u4 = 0,
/// STATUS_SEL [4:4]
/// Comparison used for the MOV x, STATUS instruction.
STATUS_SEL: u1 = 0,
/// unused [5:6]
_unused5: u2 = 0,
/// WRAP_BOTTOM [7:11]
/// After reaching wrap_top, execution is wrapped to this address.
WRAP_BOTTOM: u5 = 0,
/// WRAP_TOP [12:16]
/// After reaching this address, execution is wrapped to wrap_bottom.\n
WRAP_TOP: u5 = 31,
/// OUT_STICKY [17:17]
/// Continuously assert the most recent OUT/SET to the pins
OUT_STICKY: u1 = 0,
/// INLINE_OUT_EN [18:18]
/// If 1, use a bit of OUT data as an auxiliary write enable\n
INLINE_OUT_EN: u1 = 0,
/// OUT_EN_SEL [19:23]
/// Which data bit to use for inline OUT enable
OUT_EN_SEL: u5 = 0,
/// JMP_PIN [24:28]
/// The GPIO number to use as condition for JMP PIN. Unaffected by input mapping.
JMP_PIN: u5 = 0,
/// SIDE_PINDIR [29:29]
/// If 1, side-set data is asserted to pin directions, instead of pin values
SIDE_PINDIR: u1 = 0,
/// SIDE_EN [30:30]
/// If 1, the MSB of the Delay/Side-set instruction field is used as side-set enable, rather than a side-set data bit. This allows instructions to perform side-set optionally, rather than on every instruction, but the maximum possible side-set width is reduced from 5 to 4. Note that the value of PINCTRL_SIDESET_COUNT is inclusive of this enable bit.
SIDE_EN: u1 = 0,
/// EXEC_STALLED [31:31]
/// If 1, an instruction written to SMx_INSTR is stalled, and latched by the state machine. Will clear to 0 once this instruction completes.
EXEC_STALLED: u1 = 0,
};
/// Execution/behavioural settings for state machine 2
pub const SM2_EXECCTRL = Register(SM2_EXECCTRL_val).init(base_address + 0xfc);

/// SM2_CLKDIV
const SM2_CLKDIV_val = packed struct {
/// unused [0:7]
_unused0: u8 = 0,
/// FRAC [8:15]
/// Fractional part of clock divisor
FRAC: u8 = 0,
/// INT [16:31]
/// Effective frequency is sysclk/(int + frac/256).\n
INT: u16 = 1,
};
/// Clock divisor register for state machine 2\n
pub const SM2_CLKDIV = Register(SM2_CLKDIV_val).init(base_address + 0xf8);

/// SM1_PINCTRL
const SM1_PINCTRL_val = packed struct {
/// OUT_BASE [0:4]
/// The lowest-numbered pin that will be affected by an OUT PINS, OUT PINDIRS or MOV PINS instruction. The data written to this pin will always be the least-significant bit of the OUT or MOV data.
OUT_BASE: u5 = 0,
/// SET_BASE [5:9]
/// The lowest-numbered pin that will be affected by a SET PINS or SET PINDIRS instruction. The data written to this pin is the least-significant bit of the SET data.
SET_BASE: u5 = 0,
/// SIDESET_BASE [10:14]
/// The lowest-numbered pin that will be affected by a side-set operation. The MSBs of an instruction's side-set/delay field (up to 5, determined by SIDESET_COUNT) are used for side-set data, with the remaining LSBs used for delay. The least-significant bit of the side-set portion is the bit written to this pin, with more-significant bits written to higher-numbered pins.
SIDESET_BASE: u5 = 0,
/// IN_BASE [15:19]
/// The pin which is mapped to the least-significant bit of a state machine's IN data bus. Higher-numbered pins are mapped to consecutively more-significant data bits, with a modulo of 32 applied to pin number.
IN_BASE: u5 = 0,
/// OUT_COUNT [20:25]
/// The number of pins asserted by an OUT PINS, OUT PINDIRS or MOV PINS instruction. In the range 0 to 32 inclusive.
OUT_COUNT: u6 = 0,
/// SET_COUNT [26:28]
/// The number of pins asserted by a SET. In the range 0 to 5 inclusive.
SET_COUNT: u3 = 5,
/// SIDESET_COUNT [29:31]
/// The number of MSBs of the Delay/Side-set instruction field which are used for side-set. Inclusive of the enable bit, if present. Minimum of 0 (all delay bits, no side-set) and maximum of 5 (all side-set, no delay).
SIDESET_COUNT: u3 = 0,
};
/// State machine pin control
pub const SM1_PINCTRL = Register(SM1_PINCTRL_val).init(base_address + 0xf4);

/// SM1_INSTR
const SM1_INSTR_val = packed struct {
/// SM1_INSTR [0:15]
/// No description
SM1_INSTR: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Read to see the instruction currently addressed by state machine 1's program counter\n
pub const SM1_INSTR = Register(SM1_INSTR_val).init(base_address + 0xf0);

/// SM1_ADDR
const SM1_ADDR_val = packed struct {
/// SM1_ADDR [0:4]
/// No description
SM1_ADDR: u5 = 0,
/// unused [5:31]
_unused5: u3 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Current instruction address of state machine 1
pub const SM1_ADDR = Register(SM1_ADDR_val).init(base_address + 0xec);

/// SM1_SHIFTCTRL
const SM1_SHIFTCTRL_val = packed struct {
/// unused [0:15]
_unused0: u8 = 0,
_unused8: u8 = 0,
/// AUTOPUSH [16:16]
/// Push automatically when the input shift register is filled, i.e. on an IN instruction which causes the input shift counter to reach or exceed PUSH_THRESH.
AUTOPUSH: u1 = 0,
/// AUTOPULL [17:17]
/// Pull automatically when the output shift register is emptied, i.e. on or following an OUT instruction which causes the output shift counter to reach or exceed PULL_THRESH.
AUTOPULL: u1 = 0,
/// IN_SHIFTDIR [18:18]
/// 1 = shift input shift register to right (data enters from left). 0 = to left.
IN_SHIFTDIR: u1 = 1,
/// OUT_SHIFTDIR [19:19]
/// 1 = shift out of output shift register to right. 0 = to left.
OUT_SHIFTDIR: u1 = 1,
/// PUSH_THRESH [20:24]
/// Number of bits shifted into ISR before autopush, or conditional push (PUSH IFFULL), will take place.\n
PUSH_THRESH: u5 = 0,
/// PULL_THRESH [25:29]
/// Number of bits shifted out of OSR before autopull, or conditional pull (PULL IFEMPTY), will take place.\n
PULL_THRESH: u5 = 0,
/// FJOIN_TX [30:30]
/// When 1, TX FIFO steals the RX FIFO's storage, and becomes twice as deep.\n
FJOIN_TX: u1 = 0,
/// FJOIN_RX [31:31]
/// When 1, RX FIFO steals the TX FIFO's storage, and becomes twice as deep.\n
FJOIN_RX: u1 = 0,
};
/// Control behaviour of the input/output shift registers for state machine 1
pub const SM1_SHIFTCTRL = Register(SM1_SHIFTCTRL_val).init(base_address + 0xe8);

/// SM1_EXECCTRL
const SM1_EXECCTRL_val = packed struct {
/// STATUS_N [0:3]
/// Comparison level for the MOV x, STATUS instruction
STATUS_N: u4 = 0,
/// STATUS_SEL [4:4]
/// Comparison used for the MOV x, STATUS instruction.
STATUS_SEL: u1 = 0,
/// unused [5:6]
_unused5: u2 = 0,
/// WRAP_BOTTOM [7:11]
/// After reaching wrap_top, execution is wrapped to this address.
WRAP_BOTTOM: u5 = 0,
/// WRAP_TOP [12:16]
/// After reaching this address, execution is wrapped to wrap_bottom.\n
WRAP_TOP: u5 = 31,
/// OUT_STICKY [17:17]
/// Continuously assert the most recent OUT/SET to the pins
OUT_STICKY: u1 = 0,
/// INLINE_OUT_EN [18:18]
/// If 1, use a bit of OUT data as an auxiliary write enable\n
INLINE_OUT_EN: u1 = 0,
/// OUT_EN_SEL [19:23]
/// Which data bit to use for inline OUT enable
OUT_EN_SEL: u5 = 0,
/// JMP_PIN [24:28]
/// The GPIO number to use as condition for JMP PIN. Unaffected by input mapping.
JMP_PIN: u5 = 0,
/// SIDE_PINDIR [29:29]
/// If 1, side-set data is asserted to pin directions, instead of pin values
SIDE_PINDIR: u1 = 0,
/// SIDE_EN [30:30]
/// If 1, the MSB of the Delay/Side-set instruction field is used as side-set enable, rather than a side-set data bit. This allows instructions to perform side-set optionally, rather than on every instruction, but the maximum possible side-set width is reduced from 5 to 4. Note that the value of PINCTRL_SIDESET_COUNT is inclusive of this enable bit.
SIDE_EN: u1 = 0,
/// EXEC_STALLED [31:31]
/// If 1, an instruction written to SMx_INSTR is stalled, and latched by the state machine. Will clear to 0 once this instruction completes.
EXEC_STALLED: u1 = 0,
};
/// Execution/behavioural settings for state machine 1
pub const SM1_EXECCTRL = Register(SM1_EXECCTRL_val).init(base_address + 0xe4);

/// SM1_CLKDIV
const SM1_CLKDIV_val = packed struct {
/// unused [0:7]
_unused0: u8 = 0,
/// FRAC [8:15]
/// Fractional part of clock divisor
FRAC: u8 = 0,
/// INT [16:31]
/// Effective frequency is sysclk/(int + frac/256).\n
INT: u16 = 1,
};
/// Clock divisor register for state machine 1\n
pub const SM1_CLKDIV = Register(SM1_CLKDIV_val).init(base_address + 0xe0);

/// SM0_PINCTRL
const SM0_PINCTRL_val = packed struct {
/// OUT_BASE [0:4]
/// The lowest-numbered pin that will be affected by an OUT PINS, OUT PINDIRS or MOV PINS instruction. The data written to this pin will always be the least-significant bit of the OUT or MOV data.
OUT_BASE: u5 = 0,
/// SET_BASE [5:9]
/// The lowest-numbered pin that will be affected by a SET PINS or SET PINDIRS instruction. The data written to this pin is the least-significant bit of the SET data.
SET_BASE: u5 = 0,
/// SIDESET_BASE [10:14]
/// The lowest-numbered pin that will be affected by a side-set operation. The MSBs of an instruction's side-set/delay field (up to 5, determined by SIDESET_COUNT) are used for side-set data, with the remaining LSBs used for delay. The least-significant bit of the side-set portion is the bit written to this pin, with more-significant bits written to higher-numbered pins.
SIDESET_BASE: u5 = 0,
/// IN_BASE [15:19]
/// The pin which is mapped to the least-significant bit of a state machine's IN data bus. Higher-numbered pins are mapped to consecutively more-significant data bits, with a modulo of 32 applied to pin number.
IN_BASE: u5 = 0,
/// OUT_COUNT [20:25]
/// The number of pins asserted by an OUT PINS, OUT PINDIRS or MOV PINS instruction. In the range 0 to 32 inclusive.
OUT_COUNT: u6 = 0,
/// SET_COUNT [26:28]
/// The number of pins asserted by a SET. In the range 0 to 5 inclusive.
SET_COUNT: u3 = 5,
/// SIDESET_COUNT [29:31]
/// The number of MSBs of the Delay/Side-set instruction field which are used for side-set. Inclusive of the enable bit, if present. Minimum of 0 (all delay bits, no side-set) and maximum of 5 (all side-set, no delay).
SIDESET_COUNT: u3 = 0,
};
/// State machine pin control
pub const SM0_PINCTRL = Register(SM0_PINCTRL_val).init(base_address + 0xdc);

/// SM0_INSTR
const SM0_INSTR_val = packed struct {
/// SM0_INSTR [0:15]
/// No description
SM0_INSTR: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Read to see the instruction currently addressed by state machine 0's program counter\n
pub const SM0_INSTR = Register(SM0_INSTR_val).init(base_address + 0xd8);

/// SM0_ADDR
const SM0_ADDR_val = packed struct {
/// SM0_ADDR [0:4]
/// No description
SM0_ADDR: u5 = 0,
/// unused [5:31]
_unused5: u3 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Current instruction address of state machine 0
pub const SM0_ADDR = Register(SM0_ADDR_val).init(base_address + 0xd4);

/// SM0_SHIFTCTRL
const SM0_SHIFTCTRL_val = packed struct {
/// unused [0:15]
_unused0: u8 = 0,
_unused8: u8 = 0,
/// AUTOPUSH [16:16]
/// Push automatically when the input shift register is filled, i.e. on an IN instruction which causes the input shift counter to reach or exceed PUSH_THRESH.
AUTOPUSH: u1 = 0,
/// AUTOPULL [17:17]
/// Pull automatically when the output shift register is emptied, i.e. on or following an OUT instruction which causes the output shift counter to reach or exceed PULL_THRESH.
AUTOPULL: u1 = 0,
/// IN_SHIFTDIR [18:18]
/// 1 = shift input shift register to right (data enters from left). 0 = to left.
IN_SHIFTDIR: u1 = 1,
/// OUT_SHIFTDIR [19:19]
/// 1 = shift out of output shift register to right. 0 = to left.
OUT_SHIFTDIR: u1 = 1,
/// PUSH_THRESH [20:24]
/// Number of bits shifted into ISR before autopush, or conditional push (PUSH IFFULL), will take place.\n
PUSH_THRESH: u5 = 0,
/// PULL_THRESH [25:29]
/// Number of bits shifted out of OSR before autopull, or conditional pull (PULL IFEMPTY), will take place.\n
PULL_THRESH: u5 = 0,
/// FJOIN_TX [30:30]
/// When 1, TX FIFO steals the RX FIFO's storage, and becomes twice as deep.\n
FJOIN_TX: u1 = 0,
/// FJOIN_RX [31:31]
/// When 1, RX FIFO steals the TX FIFO's storage, and becomes twice as deep.\n
FJOIN_RX: u1 = 0,
};
/// Control behaviour of the input/output shift registers for state machine 0
pub const SM0_SHIFTCTRL = Register(SM0_SHIFTCTRL_val).init(base_address + 0xd0);

/// SM0_EXECCTRL
const SM0_EXECCTRL_val = packed struct {
/// STATUS_N [0:3]
/// Comparison level for the MOV x, STATUS instruction
STATUS_N: u4 = 0,
/// STATUS_SEL [4:4]
/// Comparison used for the MOV x, STATUS instruction.
STATUS_SEL: u1 = 0,
/// unused [5:6]
_unused5: u2 = 0,
/// WRAP_BOTTOM [7:11]
/// After reaching wrap_top, execution is wrapped to this address.
WRAP_BOTTOM: u5 = 0,
/// WRAP_TOP [12:16]
/// After reaching this address, execution is wrapped to wrap_bottom.\n
WRAP_TOP: u5 = 31,
/// OUT_STICKY [17:17]
/// Continuously assert the most recent OUT/SET to the pins
OUT_STICKY: u1 = 0,
/// INLINE_OUT_EN [18:18]
/// If 1, use a bit of OUT data as an auxiliary write enable\n
INLINE_OUT_EN: u1 = 0,
/// OUT_EN_SEL [19:23]
/// Which data bit to use for inline OUT enable
OUT_EN_SEL: u5 = 0,
/// JMP_PIN [24:28]
/// The GPIO number to use as condition for JMP PIN. Unaffected by input mapping.
JMP_PIN: u5 = 0,
/// SIDE_PINDIR [29:29]
/// If 1, side-set data is asserted to pin directions, instead of pin values
SIDE_PINDIR: u1 = 0,
/// SIDE_EN [30:30]
/// If 1, the MSB of the Delay/Side-set instruction field is used as side-set enable, rather than a side-set data bit. This allows instructions to perform side-set optionally, rather than on every instruction, but the maximum possible side-set width is reduced from 5 to 4. Note that the value of PINCTRL_SIDESET_COUNT is inclusive of this enable bit.
SIDE_EN: u1 = 0,
/// EXEC_STALLED [31:31]
/// If 1, an instruction written to SMx_INSTR is stalled, and latched by the state machine. Will clear to 0 once this instruction completes.
EXEC_STALLED: u1 = 0,
};
/// Execution/behavioural settings for state machine 0
pub const SM0_EXECCTRL = Register(SM0_EXECCTRL_val).init(base_address + 0xcc);

/// SM0_CLKDIV
const SM0_CLKDIV_val = packed struct {
/// unused [0:7]
_unused0: u8 = 0,
/// FRAC [8:15]
/// Fractional part of clock divisor
FRAC: u8 = 0,
/// INT [16:31]
/// Effective frequency is sysclk/(int + frac/256).\n
INT: u16 = 1,
};
/// Clock divisor register for state machine 0\n
pub const SM0_CLKDIV = Register(SM0_CLKDIV_val).init(base_address + 0xc8);

/// INSTR_MEM31
const INSTR_MEM31_val = packed struct {
/// INSTR_MEM31 [0:15]
/// No description
INSTR_MEM31: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 31
pub const INSTR_MEM31 = Register(INSTR_MEM31_val).init(base_address + 0xc4);

/// INSTR_MEM30
const INSTR_MEM30_val = packed struct {
/// INSTR_MEM30 [0:15]
/// No description
INSTR_MEM30: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 30
pub const INSTR_MEM30 = Register(INSTR_MEM30_val).init(base_address + 0xc0);

/// INSTR_MEM29
const INSTR_MEM29_val = packed struct {
/// INSTR_MEM29 [0:15]
/// No description
INSTR_MEM29: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 29
pub const INSTR_MEM29 = Register(INSTR_MEM29_val).init(base_address + 0xbc);

/// INSTR_MEM28
const INSTR_MEM28_val = packed struct {
/// INSTR_MEM28 [0:15]
/// No description
INSTR_MEM28: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 28
pub const INSTR_MEM28 = Register(INSTR_MEM28_val).init(base_address + 0xb8);

/// INSTR_MEM27
const INSTR_MEM27_val = packed struct {
/// INSTR_MEM27 [0:15]
/// No description
INSTR_MEM27: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 27
pub const INSTR_MEM27 = Register(INSTR_MEM27_val).init(base_address + 0xb4);

/// INSTR_MEM26
const INSTR_MEM26_val = packed struct {
/// INSTR_MEM26 [0:15]
/// No description
INSTR_MEM26: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 26
pub const INSTR_MEM26 = Register(INSTR_MEM26_val).init(base_address + 0xb0);

/// INSTR_MEM25
const INSTR_MEM25_val = packed struct {
/// INSTR_MEM25 [0:15]
/// No description
INSTR_MEM25: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 25
pub const INSTR_MEM25 = Register(INSTR_MEM25_val).init(base_address + 0xac);

/// INSTR_MEM24
const INSTR_MEM24_val = packed struct {
/// INSTR_MEM24 [0:15]
/// No description
INSTR_MEM24: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 24
pub const INSTR_MEM24 = Register(INSTR_MEM24_val).init(base_address + 0xa8);

/// INSTR_MEM23
const INSTR_MEM23_val = packed struct {
/// INSTR_MEM23 [0:15]
/// No description
INSTR_MEM23: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 23
pub const INSTR_MEM23 = Register(INSTR_MEM23_val).init(base_address + 0xa4);

/// INSTR_MEM22
const INSTR_MEM22_val = packed struct {
/// INSTR_MEM22 [0:15]
/// No description
INSTR_MEM22: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 22
pub const INSTR_MEM22 = Register(INSTR_MEM22_val).init(base_address + 0xa0);

/// INSTR_MEM21
const INSTR_MEM21_val = packed struct {
/// INSTR_MEM21 [0:15]
/// No description
INSTR_MEM21: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 21
pub const INSTR_MEM21 = Register(INSTR_MEM21_val).init(base_address + 0x9c);

/// INSTR_MEM20
const INSTR_MEM20_val = packed struct {
/// INSTR_MEM20 [0:15]
/// No description
INSTR_MEM20: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 20
pub const INSTR_MEM20 = Register(INSTR_MEM20_val).init(base_address + 0x98);

/// INSTR_MEM19
const INSTR_MEM19_val = packed struct {
/// INSTR_MEM19 [0:15]
/// No description
INSTR_MEM19: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 19
pub const INSTR_MEM19 = Register(INSTR_MEM19_val).init(base_address + 0x94);

/// INSTR_MEM18
const INSTR_MEM18_val = packed struct {
/// INSTR_MEM18 [0:15]
/// No description
INSTR_MEM18: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 18
pub const INSTR_MEM18 = Register(INSTR_MEM18_val).init(base_address + 0x90);

/// INSTR_MEM17
const INSTR_MEM17_val = packed struct {
/// INSTR_MEM17 [0:15]
/// No description
INSTR_MEM17: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 17
pub const INSTR_MEM17 = Register(INSTR_MEM17_val).init(base_address + 0x8c);

/// INSTR_MEM16
const INSTR_MEM16_val = packed struct {
/// INSTR_MEM16 [0:15]
/// No description
INSTR_MEM16: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 16
pub const INSTR_MEM16 = Register(INSTR_MEM16_val).init(base_address + 0x88);

/// INSTR_MEM15
const INSTR_MEM15_val = packed struct {
/// INSTR_MEM15 [0:15]
/// No description
INSTR_MEM15: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 15
pub const INSTR_MEM15 = Register(INSTR_MEM15_val).init(base_address + 0x84);

/// INSTR_MEM14
const INSTR_MEM14_val = packed struct {
/// INSTR_MEM14 [0:15]
/// No description
INSTR_MEM14: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 14
pub const INSTR_MEM14 = Register(INSTR_MEM14_val).init(base_address + 0x80);

/// INSTR_MEM13
const INSTR_MEM13_val = packed struct {
/// INSTR_MEM13 [0:15]
/// No description
INSTR_MEM13: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 13
pub const INSTR_MEM13 = Register(INSTR_MEM13_val).init(base_address + 0x7c);

/// INSTR_MEM12
const INSTR_MEM12_val = packed struct {
/// INSTR_MEM12 [0:15]
/// No description
INSTR_MEM12: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 12
pub const INSTR_MEM12 = Register(INSTR_MEM12_val).init(base_address + 0x78);

/// INSTR_MEM11
const INSTR_MEM11_val = packed struct {
/// INSTR_MEM11 [0:15]
/// No description
INSTR_MEM11: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 11
pub const INSTR_MEM11 = Register(INSTR_MEM11_val).init(base_address + 0x74);

/// INSTR_MEM10
const INSTR_MEM10_val = packed struct {
/// INSTR_MEM10 [0:15]
/// No description
INSTR_MEM10: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 10
pub const INSTR_MEM10 = Register(INSTR_MEM10_val).init(base_address + 0x70);

/// INSTR_MEM9
const INSTR_MEM9_val = packed struct {
/// INSTR_MEM9 [0:15]
/// No description
INSTR_MEM9: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 9
pub const INSTR_MEM9 = Register(INSTR_MEM9_val).init(base_address + 0x6c);

/// INSTR_MEM8
const INSTR_MEM8_val = packed struct {
/// INSTR_MEM8 [0:15]
/// No description
INSTR_MEM8: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 8
pub const INSTR_MEM8 = Register(INSTR_MEM8_val).init(base_address + 0x68);

/// INSTR_MEM7
const INSTR_MEM7_val = packed struct {
/// INSTR_MEM7 [0:15]
/// No description
INSTR_MEM7: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 7
pub const INSTR_MEM7 = Register(INSTR_MEM7_val).init(base_address + 0x64);

/// INSTR_MEM6
const INSTR_MEM6_val = packed struct {
/// INSTR_MEM6 [0:15]
/// No description
INSTR_MEM6: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 6
pub const INSTR_MEM6 = Register(INSTR_MEM6_val).init(base_address + 0x60);

/// INSTR_MEM5
const INSTR_MEM5_val = packed struct {
/// INSTR_MEM5 [0:15]
/// No description
INSTR_MEM5: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 5
pub const INSTR_MEM5 = Register(INSTR_MEM5_val).init(base_address + 0x5c);

/// INSTR_MEM4
const INSTR_MEM4_val = packed struct {
/// INSTR_MEM4 [0:15]
/// No description
INSTR_MEM4: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 4
pub const INSTR_MEM4 = Register(INSTR_MEM4_val).init(base_address + 0x58);

/// INSTR_MEM3
const INSTR_MEM3_val = packed struct {
/// INSTR_MEM3 [0:15]
/// No description
INSTR_MEM3: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 3
pub const INSTR_MEM3 = Register(INSTR_MEM3_val).init(base_address + 0x54);

/// INSTR_MEM2
const INSTR_MEM2_val = packed struct {
/// INSTR_MEM2 [0:15]
/// No description
INSTR_MEM2: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 2
pub const INSTR_MEM2 = Register(INSTR_MEM2_val).init(base_address + 0x50);

/// INSTR_MEM1
const INSTR_MEM1_val = packed struct {
/// INSTR_MEM1 [0:15]
/// No description
INSTR_MEM1: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 1
pub const INSTR_MEM1 = Register(INSTR_MEM1_val).init(base_address + 0x4c);

/// INSTR_MEM0
const INSTR_MEM0_val = packed struct {
/// INSTR_MEM0 [0:15]
/// No description
INSTR_MEM0: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Write-only access to instruction memory location 0
pub const INSTR_MEM0 = Register(INSTR_MEM0_val).init(base_address + 0x48);

/// DBG_CFGINFO
const DBG_CFGINFO_val = packed struct {
/// FIFO_DEPTH [0:5]
/// The depth of the state machine TX/RX FIFOs, measured in words.\n
FIFO_DEPTH: u6 = 0,
/// unused [6:7]
_unused6: u2 = 0,
/// SM_COUNT [8:11]
/// The number of state machines this PIO instance is equipped with.
SM_COUNT: u4 = 0,
/// unused [12:15]
_unused12: u4 = 0,
/// IMEM_SIZE [16:21]
/// The size of the instruction memory, measured in units of one instruction
IMEM_SIZE: u6 = 0,
/// unused [22:31]
_unused22: u2 = 0,
_unused24: u8 = 0,
};
/// The PIO hardware has some free parameters that may vary between chip products.\n
pub const DBG_CFGINFO = Register(DBG_CFGINFO_val).init(base_address + 0x44);

/// DBG_PADOE
const DBG_PADOE_val = packed struct {
DBG_PADOE_0: u8 = 0,
DBG_PADOE_1: u8 = 0,
DBG_PADOE_2: u8 = 0,
DBG_PADOE_3: u8 = 0,
};
/// Read to sample the pad output enables (direction) PIO is currently driving to the GPIOs.
pub const DBG_PADOE = Register(DBG_PADOE_val).init(base_address + 0x40);

/// DBG_PADOUT
const DBG_PADOUT_val = packed struct {
DBG_PADOUT_0: u8 = 0,
DBG_PADOUT_1: u8 = 0,
DBG_PADOUT_2: u8 = 0,
DBG_PADOUT_3: u8 = 0,
};
/// Read to sample the pad output values PIO is currently driving to the GPIOs.
pub const DBG_PADOUT = Register(DBG_PADOUT_val).init(base_address + 0x3c);

/// INPUT_SYNC_BYPASS
const INPUT_SYNC_BYPASS_val = packed struct {
INPUT_SYNC_BYPASS_0: u8 = 0,
INPUT_SYNC_BYPASS_1: u8 = 0,
INPUT_SYNC_BYPASS_2: u8 = 0,
INPUT_SYNC_BYPASS_3: u8 = 0,
};
/// There is a 2-flipflop synchronizer on each GPIO input, which protects PIO logic from metastabilities. This increases input delay, and for fast synchronous IO (e.g. SPI) these synchronizers may need to be bypassed. Each bit in this register corresponds to one GPIO.\n
pub const INPUT_SYNC_BYPASS = Register(INPUT_SYNC_BYPASS_val).init(base_address + 0x38);

/// IRQ_FORCE
const IRQ_FORCE_val = packed struct {
/// IRQ_FORCE [0:7]
/// No description
IRQ_FORCE: u8 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Writing a 1 to each of these bits will forcibly assert the corresponding IRQ. Note this is different to the INTF register: writing here affects PIO internal state. INTF just asserts the processor-facing IRQ signal for testing ISRs, and is not visible to the state machines.
pub const IRQ_FORCE = Register(IRQ_FORCE_val).init(base_address + 0x34);

/// IRQ
const IRQ_val = packed struct {
/// IRQ [0:7]
/// No description
IRQ: u8 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// State machine IRQ flags register. Write 1 to clear. There are 8 state machine IRQ flags, which can be set, cleared, and waited on by the state machines. There's no fixed association between flags and state machines -- any state machine can use any flag.\n\n
pub const IRQ = Register(IRQ_val).init(base_address + 0x30);

/// RXF3
const RXF3_val = packed struct {
RXF3_0: u8 = 0,
RXF3_1: u8 = 0,
RXF3_2: u8 = 0,
RXF3_3: u8 = 0,
};
/// Direct read access to the RX FIFO for this state machine. Each read pops one word from the FIFO. Attempting to read from an empty FIFO has no effect on the FIFO state, and sets the sticky FDEBUG_RXUNDER error flag for this FIFO. The data returned to the system on a read from an empty FIFO is undefined.
pub const RXF3 = Register(RXF3_val).init(base_address + 0x2c);

/// RXF2
const RXF2_val = packed struct {
RXF2_0: u8 = 0,
RXF2_1: u8 = 0,
RXF2_2: u8 = 0,
RXF2_3: u8 = 0,
};
/// Direct read access to the RX FIFO for this state machine. Each read pops one word from the FIFO. Attempting to read from an empty FIFO has no effect on the FIFO state, and sets the sticky FDEBUG_RXUNDER error flag for this FIFO. The data returned to the system on a read from an empty FIFO is undefined.
pub const RXF2 = Register(RXF2_val).init(base_address + 0x28);

/// RXF1
const RXF1_val = packed struct {
RXF1_0: u8 = 0,
RXF1_1: u8 = 0,
RXF1_2: u8 = 0,
RXF1_3: u8 = 0,
};
/// Direct read access to the RX FIFO for this state machine. Each read pops one word from the FIFO. Attempting to read from an empty FIFO has no effect on the FIFO state, and sets the sticky FDEBUG_RXUNDER error flag for this FIFO. The data returned to the system on a read from an empty FIFO is undefined.
pub const RXF1 = Register(RXF1_val).init(base_address + 0x24);

/// RXF0
const RXF0_val = packed struct {
RXF0_0: u8 = 0,
RXF0_1: u8 = 0,
RXF0_2: u8 = 0,
RXF0_3: u8 = 0,
};
/// Direct read access to the RX FIFO for this state machine. Each read pops one word from the FIFO. Attempting to read from an empty FIFO has no effect on the FIFO state, and sets the sticky FDEBUG_RXUNDER error flag for this FIFO. The data returned to the system on a read from an empty FIFO is undefined.
pub const RXF0 = Register(RXF0_val).init(base_address + 0x20);

/// TXF3
const TXF3_val = packed struct {
TXF3_0: u8 = 0,
TXF3_1: u8 = 0,
TXF3_2: u8 = 0,
TXF3_3: u8 = 0,
};
/// Direct write access to the TX FIFO for this state machine. Each write pushes one word to the FIFO. Attempting to write to a full FIFO has no effect on the FIFO state or contents, and sets the sticky FDEBUG_TXOVER error flag for this FIFO.
pub const TXF3 = Register(TXF3_val).init(base_address + 0x1c);

/// TXF2
const TXF2_val = packed struct {
TXF2_0: u8 = 0,
TXF2_1: u8 = 0,
TXF2_2: u8 = 0,
TXF2_3: u8 = 0,
};
/// Direct write access to the TX FIFO for this state machine. Each write pushes one word to the FIFO. Attempting to write to a full FIFO has no effect on the FIFO state or contents, and sets the sticky FDEBUG_TXOVER error flag for this FIFO.
pub const TXF2 = Register(TXF2_val).init(base_address + 0x18);

/// TXF1
const TXF1_val = packed struct {
TXF1_0: u8 = 0,
TXF1_1: u8 = 0,
TXF1_2: u8 = 0,
TXF1_3: u8 = 0,
};
/// Direct write access to the TX FIFO for this state machine. Each write pushes one word to the FIFO. Attempting to write to a full FIFO has no effect on the FIFO state or contents, and sets the sticky FDEBUG_TXOVER error flag for this FIFO.
pub const TXF1 = Register(TXF1_val).init(base_address + 0x14);

/// TXF0
const TXF0_val = packed struct {
TXF0_0: u8 = 0,
TXF0_1: u8 = 0,
TXF0_2: u8 = 0,
TXF0_3: u8 = 0,
};
/// Direct write access to the TX FIFO for this state machine. Each write pushes one word to the FIFO. Attempting to write to a full FIFO has no effect on the FIFO state or contents, and sets the sticky FDEBUG_TXOVER error flag for this FIFO.
pub const TXF0 = Register(TXF0_val).init(base_address + 0x10);

/// FLEVEL
const FLEVEL_val = packed struct {
/// TX0 [0:3]
/// No description
TX0: u4 = 0,
/// RX0 [4:7]
/// No description
RX0: u4 = 0,
/// TX1 [8:11]
/// No description
TX1: u4 = 0,
/// RX1 [12:15]
/// No description
RX1: u4 = 0,
/// TX2 [16:19]
/// No description
TX2: u4 = 0,
/// RX2 [20:23]
/// No description
RX2: u4 = 0,
/// TX3 [24:27]
/// No description
TX3: u4 = 0,
/// RX3 [28:31]
/// No description
RX3: u4 = 0,
};
/// FIFO levels
pub const FLEVEL = Register(FLEVEL_val).init(base_address + 0xc);

/// FDEBUG
const FDEBUG_val = packed struct {
/// RXSTALL [0:3]
/// State machine has stalled on full RX FIFO during a blocking PUSH, or an IN with autopush enabled. This flag is also set when a nonblocking PUSH to a full FIFO took place, in which case the state machine has dropped data. Write 1 to clear.
RXSTALL: u4 = 0,
/// unused [4:7]
_unused4: u4 = 0,
/// RXUNDER [8:11]
/// RX FIFO underflow (i.e. read-on-empty by the system) has occurred. Write 1 to clear. Note that read-on-empty does not perturb the state of the FIFO in any way, but the data returned by reading from an empty FIFO is undefined, so this flag generally only becomes set due to some kind of software error.
RXUNDER: u4 = 0,
/// unused [12:15]
_unused12: u4 = 0,
/// TXOVER [16:19]
/// TX FIFO overflow (i.e. write-on-full by the system) has occurred. Write 1 to clear. Note that write-on-full does not alter the state or contents of the FIFO in any way, but the data that the system attempted to write is dropped, so if this flag is set, your software has quite likely dropped some data on the floor.
TXOVER: u4 = 0,
/// unused [20:23]
_unused20: u4 = 0,
/// TXSTALL [24:27]
/// State machine has stalled on empty TX FIFO during a blocking PULL, or an OUT with autopull enabled. Write 1 to clear.
TXSTALL: u4 = 0,
/// unused [28:31]
_unused28: u4 = 0,
};
/// FIFO debug register
pub const FDEBUG = Register(FDEBUG_val).init(base_address + 0x8);

/// FSTAT
const FSTAT_val = packed struct {
/// RXFULL [0:3]
/// State machine RX FIFO is full
RXFULL: u4 = 0,
/// unused [4:7]
_unused4: u4 = 0,
/// RXEMPTY [8:11]
/// State machine RX FIFO is empty
RXEMPTY: u4 = 15,
/// unused [12:15]
_unused12: u4 = 0,
/// TXFULL [16:19]
/// State machine TX FIFO is full
TXFULL: u4 = 0,
/// unused [20:23]
_unused20: u4 = 0,
/// TXEMPTY [24:27]
/// State machine TX FIFO is empty
TXEMPTY: u4 = 15,
/// unused [28:31]
_unused28: u4 = 0,
};
/// FIFO status register
pub const FSTAT = Register(FSTAT_val).init(base_address + 0x4);

/// CTRL
const CTRL_val = packed struct {
/// SM_ENABLE [0:3]
/// Enable/disable each of the four state machines by writing 1/0 to each of these four bits. When disabled, a state machine will cease executing instructions, except those written directly to SMx_INSTR by the system. Multiple bits can be set/cleared at once to run/halt multiple state machines simultaneously.
SM_ENABLE: u4 = 0,
/// SM_RESTART [4:7]
/// Write 1 to instantly clear internal SM state which may be otherwise difficult to access and will affect future execution.\n\n
SM_RESTART: u4 = 0,
/// CLKDIV_RESTART [8:11]
/// Restart a state machine's clock divider from an initial phase of 0. Clock dividers are free-running, so once started, their output (including fractional jitter) is completely determined by the integer/fractional divisor configured in SMx_CLKDIV. This means that, if multiple clock dividers with the same divisor are restarted simultaneously, by writing multiple 1 bits to this field, the execution clocks of those state machines will run in precise lockstep.\n\n
CLKDIV_RESTART: u4 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// PIO control register
pub const CTRL = Register(CTRL_val).init(base_address + 0x0);
};

/// Single-cycle IO block\n
pub const SIO = struct {

const base_address = 0xd0000000;
/// SPINLOCK31
const SPINLOCK31_val = packed struct {
SPINLOCK31_0: u8 = 0,
SPINLOCK31_1: u8 = 0,
SPINLOCK31_2: u8 = 0,
SPINLOCK31_3: u8 = 0,
};
/// Reading from a spinlock address will:\n
pub const SPINLOCK31 = Register(SPINLOCK31_val).init(base_address + 0x17c);

/// SPINLOCK30
const SPINLOCK30_val = packed struct {
SPINLOCK30_0: u8 = 0,
SPINLOCK30_1: u8 = 0,
SPINLOCK30_2: u8 = 0,
SPINLOCK30_3: u8 = 0,
};
/// Reading from a spinlock address will:\n
pub const SPINLOCK30 = Register(SPINLOCK30_val).init(base_address + 0x178);

/// SPINLOCK29
const SPINLOCK29_val = packed struct {
SPINLOCK29_0: u8 = 0,
SPINLOCK29_1: u8 = 0,
SPINLOCK29_2: u8 = 0,
SPINLOCK29_3: u8 = 0,
};
/// Reading from a spinlock address will:\n
pub const SPINLOCK29 = Register(SPINLOCK29_val).init(base_address + 0x174);

/// SPINLOCK28
const SPINLOCK28_val = packed struct {
SPINLOCK28_0: u8 = 0,
SPINLOCK28_1: u8 = 0,
SPINLOCK28_2: u8 = 0,
SPINLOCK28_3: u8 = 0,
};
/// Reading from a spinlock address will:\n
pub const SPINLOCK28 = Register(SPINLOCK28_val).init(base_address + 0x170);

/// SPINLOCK27
const SPINLOCK27_val = packed struct {
SPINLOCK27_0: u8 = 0,
SPINLOCK27_1: u8 = 0,
SPINLOCK27_2: u8 = 0,
SPINLOCK27_3: u8 = 0,
};
/// Reading from a spinlock address will:\n
pub const SPINLOCK27 = Register(SPINLOCK27_val).init(base_address + 0x16c);

/// SPINLOCK26
const SPINLOCK26_val = packed struct {
SPINLOCK26_0: u8 = 0,
SPINLOCK26_1: u8 = 0,
SPINLOCK26_2: u8 = 0,
SPINLOCK26_3: u8 = 0,
};
/// Reading from a spinlock address will:\n
pub const SPINLOCK26 = Register(SPINLOCK26_val).init(base_address + 0x168);

/// SPINLOCK25
const SPINLOCK25_val = packed struct {
SPINLOCK25_0: u8 = 0,
SPINLOCK25_1: u8 = 0,
SPINLOCK25_2: u8 = 0,
SPINLOCK25_3: u8 = 0,
};
/// Reading from a spinlock address will:\n
pub const SPINLOCK25 = Register(SPINLOCK25_val).init(base_address + 0x164);

/// SPINLOCK24
const SPINLOCK24_val = packed struct {
SPINLOCK24_0: u8 = 0,
SPINLOCK24_1: u8 = 0,
SPINLOCK24_2: u8 = 0,
SPINLOCK24_3: u8 = 0,
};
/// Reading from a spinlock address will:\n
pub const SPINLOCK24 = Register(SPINLOCK24_val).init(base_address + 0x160);

/// SPINLOCK23
const SPINLOCK23_val = packed struct {
SPINLOCK23_0: u8 = 0,
SPINLOCK23_1: u8 = 0,
SPINLOCK23_2: u8 = 0,
SPINLOCK23_3: u8 = 0,
};
/// Reading from a spinlock address will:\n
pub const SPINLOCK23 = Register(SPINLOCK23_val).init(base_address + 0x15c);

/// SPINLOCK22
const SPINLOCK22_val = packed struct {
SPINLOCK22_0: u8 = 0,
SPINLOCK22_1: u8 = 0,
SPINLOCK22_2: u8 = 0,
SPINLOCK22_3: u8 = 0,
};
/// Reading from a spinlock address will:\n
pub const SPINLOCK22 = Register(SPINLOCK22_val).init(base_address + 0x158);

/// SPINLOCK21
const SPINLOCK21_val = packed struct {
SPINLOCK21_0: u8 = 0,
SPINLOCK21_1: u8 = 0,
SPINLOCK21_2: u8 = 0,
SPINLOCK21_3: u8 = 0,
};
/// Reading from a spinlock address will:\n
pub const SPINLOCK21 = Register(SPINLOCK21_val).init(base_address + 0x154);

/// SPINLOCK20
const SPINLOCK20_val = packed struct {
SPINLOCK20_0: u8 = 0,
SPINLOCK20_1: u8 = 0,
SPINLOCK20_2: u8 = 0,
SPINLOCK20_3: u8 = 0,
};
/// Reading from a spinlock address will:\n
pub const SPINLOCK20 = Register(SPINLOCK20_val).init(base_address + 0x150);

/// SPINLOCK19
const SPINLOCK19_val = packed struct {
SPINLOCK19_0: u8 = 0,
SPINLOCK19_1: u8 = 0,
SPINLOCK19_2: u8 = 0,
SPINLOCK19_3: u8 = 0,
};
/// Reading from a spinlock address will:\n
pub const SPINLOCK19 = Register(SPINLOCK19_val).init(base_address + 0x14c);

/// SPINLOCK18
const SPINLOCK18_val = packed struct {
SPINLOCK18_0: u8 = 0,
SPINLOCK18_1: u8 = 0,
SPINLOCK18_2: u8 = 0,
SPINLOCK18_3: u8 = 0,
};
/// Reading from a spinlock address will:\n
pub const SPINLOCK18 = Register(SPINLOCK18_val).init(base_address + 0x148);

/// SPINLOCK17
const SPINLOCK17_val = packed struct {
SPINLOCK17_0: u8 = 0,
SPINLOCK17_1: u8 = 0,
SPINLOCK17_2: u8 = 0,
SPINLOCK17_3: u8 = 0,
};
/// Reading from a spinlock address will:\n
pub const SPINLOCK17 = Register(SPINLOCK17_val).init(base_address + 0x144);

/// SPINLOCK16
const SPINLOCK16_val = packed struct {
SPINLOCK16_0: u8 = 0,
SPINLOCK16_1: u8 = 0,
SPINLOCK16_2: u8 = 0,
SPINLOCK16_3: u8 = 0,
};
/// Reading from a spinlock address will:\n
pub const SPINLOCK16 = Register(SPINLOCK16_val).init(base_address + 0x140);

/// SPINLOCK15
const SPINLOCK15_val = packed struct {
SPINLOCK15_0: u8 = 0,
SPINLOCK15_1: u8 = 0,
SPINLOCK15_2: u8 = 0,
SPINLOCK15_3: u8 = 0,
};
/// Reading from a spinlock address will:\n
pub const SPINLOCK15 = Register(SPINLOCK15_val).init(base_address + 0x13c);

/// SPINLOCK14
const SPINLOCK14_val = packed struct {
SPINLOCK14_0: u8 = 0,
SPINLOCK14_1: u8 = 0,
SPINLOCK14_2: u8 = 0,
SPINLOCK14_3: u8 = 0,
};
/// Reading from a spinlock address will:\n
pub const SPINLOCK14 = Register(SPINLOCK14_val).init(base_address + 0x138);

/// SPINLOCK13
const SPINLOCK13_val = packed struct {
SPINLOCK13_0: u8 = 0,
SPINLOCK13_1: u8 = 0,
SPINLOCK13_2: u8 = 0,
SPINLOCK13_3: u8 = 0,
};
/// Reading from a spinlock address will:\n
pub const SPINLOCK13 = Register(SPINLOCK13_val).init(base_address + 0x134);

/// SPINLOCK12
const SPINLOCK12_val = packed struct {
SPINLOCK12_0: u8 = 0,
SPINLOCK12_1: u8 = 0,
SPINLOCK12_2: u8 = 0,
SPINLOCK12_3: u8 = 0,
};
/// Reading from a spinlock address will:\n
pub const SPINLOCK12 = Register(SPINLOCK12_val).init(base_address + 0x130);

/// SPINLOCK11
const SPINLOCK11_val = packed struct {
SPINLOCK11_0: u8 = 0,
SPINLOCK11_1: u8 = 0,
SPINLOCK11_2: u8 = 0,
SPINLOCK11_3: u8 = 0,
};
/// Reading from a spinlock address will:\n
pub const SPINLOCK11 = Register(SPINLOCK11_val).init(base_address + 0x12c);

/// SPINLOCK10
const SPINLOCK10_val = packed struct {
SPINLOCK10_0: u8 = 0,
SPINLOCK10_1: u8 = 0,
SPINLOCK10_2: u8 = 0,
SPINLOCK10_3: u8 = 0,
};
/// Reading from a spinlock address will:\n
pub const SPINLOCK10 = Register(SPINLOCK10_val).init(base_address + 0x128);

/// SPINLOCK9
const SPINLOCK9_val = packed struct {
SPINLOCK9_0: u8 = 0,
SPINLOCK9_1: u8 = 0,
SPINLOCK9_2: u8 = 0,
SPINLOCK9_3: u8 = 0,
};
/// Reading from a spinlock address will:\n
pub const SPINLOCK9 = Register(SPINLOCK9_val).init(base_address + 0x124);

/// SPINLOCK8
const SPINLOCK8_val = packed struct {
SPINLOCK8_0: u8 = 0,
SPINLOCK8_1: u8 = 0,
SPINLOCK8_2: u8 = 0,
SPINLOCK8_3: u8 = 0,
};
/// Reading from a spinlock address will:\n
pub const SPINLOCK8 = Register(SPINLOCK8_val).init(base_address + 0x120);

/// SPINLOCK7
const SPINLOCK7_val = packed struct {
SPINLOCK7_0: u8 = 0,
SPINLOCK7_1: u8 = 0,
SPINLOCK7_2: u8 = 0,
SPINLOCK7_3: u8 = 0,
};
/// Reading from a spinlock address will:\n
pub const SPINLOCK7 = Register(SPINLOCK7_val).init(base_address + 0x11c);

/// SPINLOCK6
const SPINLOCK6_val = packed struct {
SPINLOCK6_0: u8 = 0,
SPINLOCK6_1: u8 = 0,
SPINLOCK6_2: u8 = 0,
SPINLOCK6_3: u8 = 0,
};
/// Reading from a spinlock address will:\n
pub const SPINLOCK6 = Register(SPINLOCK6_val).init(base_address + 0x118);

/// SPINLOCK5
const SPINLOCK5_val = packed struct {
SPINLOCK5_0: u8 = 0,
SPINLOCK5_1: u8 = 0,
SPINLOCK5_2: u8 = 0,
SPINLOCK5_3: u8 = 0,
};
/// Reading from a spinlock address will:\n
pub const SPINLOCK5 = Register(SPINLOCK5_val).init(base_address + 0x114);

/// SPINLOCK4
const SPINLOCK4_val = packed struct {
SPINLOCK4_0: u8 = 0,
SPINLOCK4_1: u8 = 0,
SPINLOCK4_2: u8 = 0,
SPINLOCK4_3: u8 = 0,
};
/// Reading from a spinlock address will:\n
pub const SPINLOCK4 = Register(SPINLOCK4_val).init(base_address + 0x110);

/// SPINLOCK3
const SPINLOCK3_val = packed struct {
SPINLOCK3_0: u8 = 0,
SPINLOCK3_1: u8 = 0,
SPINLOCK3_2: u8 = 0,
SPINLOCK3_3: u8 = 0,
};
/// Reading from a spinlock address will:\n
pub const SPINLOCK3 = Register(SPINLOCK3_val).init(base_address + 0x10c);

/// SPINLOCK2
const SPINLOCK2_val = packed struct {
SPINLOCK2_0: u8 = 0,
SPINLOCK2_1: u8 = 0,
SPINLOCK2_2: u8 = 0,
SPINLOCK2_3: u8 = 0,
};
/// Reading from a spinlock address will:\n
pub const SPINLOCK2 = Register(SPINLOCK2_val).init(base_address + 0x108);

/// SPINLOCK1
const SPINLOCK1_val = packed struct {
SPINLOCK1_0: u8 = 0,
SPINLOCK1_1: u8 = 0,
SPINLOCK1_2: u8 = 0,
SPINLOCK1_3: u8 = 0,
};
/// Reading from a spinlock address will:\n
pub const SPINLOCK1 = Register(SPINLOCK1_val).init(base_address + 0x104);

/// SPINLOCK0
const SPINLOCK0_val = packed struct {
SPINLOCK0_0: u8 = 0,
SPINLOCK0_1: u8 = 0,
SPINLOCK0_2: u8 = 0,
SPINLOCK0_3: u8 = 0,
};
/// Reading from a spinlock address will:\n
pub const SPINLOCK0 = Register(SPINLOCK0_val).init(base_address + 0x100);

/// INTERP1_BASE_1AND0
const INTERP1_BASE_1AND0_val = packed struct {
INTERP1_BASE_1AND0_0: u8 = 0,
INTERP1_BASE_1AND0_1: u8 = 0,
INTERP1_BASE_1AND0_2: u8 = 0,
INTERP1_BASE_1AND0_3: u8 = 0,
};
/// On write, the lower 16 bits go to BASE0, upper bits to BASE1 simultaneously.\n
pub const INTERP1_BASE_1AND0 = Register(INTERP1_BASE_1AND0_val).init(base_address + 0xfc);

/// INTERP1_ACCUM1_ADD
const INTERP1_ACCUM1_ADD_val = packed struct {
/// INTERP1_ACCUM1_ADD [0:23]
/// No description
INTERP1_ACCUM1_ADD: u24 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// Values written here are atomically added to ACCUM1\n
pub const INTERP1_ACCUM1_ADD = Register(INTERP1_ACCUM1_ADD_val).init(base_address + 0xf8);

/// INTERP1_ACCUM0_ADD
const INTERP1_ACCUM0_ADD_val = packed struct {
/// INTERP1_ACCUM0_ADD [0:23]
/// No description
INTERP1_ACCUM0_ADD: u24 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// Values written here are atomically added to ACCUM0\n
pub const INTERP1_ACCUM0_ADD = Register(INTERP1_ACCUM0_ADD_val).init(base_address + 0xf4);

/// INTERP1_CTRL_LANE1
const INTERP1_CTRL_LANE1_val = packed struct {
/// SHIFT [0:4]
/// Logical right-shift applied to accumulator before masking
SHIFT: u5 = 0,
/// MASK_LSB [5:9]
/// The least-significant bit allowed to pass by the mask (inclusive)
MASK_LSB: u5 = 0,
/// MASK_MSB [10:14]
/// The most-significant bit allowed to pass by the mask (inclusive)\n
MASK_MSB: u5 = 0,
/// SIGNED [15:15]
/// If SIGNED is set, the shifted and masked accumulator value is sign-extended to 32 bits\n
SIGNED: u1 = 0,
/// CROSS_INPUT [16:16]
/// If 1, feed the opposite lane's accumulator into this lane's shift + mask hardware.\n
CROSS_INPUT: u1 = 0,
/// CROSS_RESULT [17:17]
/// If 1, feed the opposite lane's result into this lane's accumulator on POP.
CROSS_RESULT: u1 = 0,
/// ADD_RAW [18:18]
/// If 1, mask + shift is bypassed for LANE1 result. This does not affect FULL result.
ADD_RAW: u1 = 0,
/// FORCE_MSB [19:20]
/// ORed into bits 29:28 of the lane result presented to the processor on the bus.\n
FORCE_MSB: u2 = 0,
/// unused [21:31]
_unused21: u3 = 0,
_unused24: u8 = 0,
};
/// Control register for lane 1
pub const INTERP1_CTRL_LANE1 = Register(INTERP1_CTRL_LANE1_val).init(base_address + 0xf0);

/// INTERP1_CTRL_LANE0
const INTERP1_CTRL_LANE0_val = packed struct {
/// SHIFT [0:4]
/// Logical right-shift applied to accumulator before masking
SHIFT: u5 = 0,
/// MASK_LSB [5:9]
/// The least-significant bit allowed to pass by the mask (inclusive)
MASK_LSB: u5 = 0,
/// MASK_MSB [10:14]
/// The most-significant bit allowed to pass by the mask (inclusive)\n
MASK_MSB: u5 = 0,
/// SIGNED [15:15]
/// If SIGNED is set, the shifted and masked accumulator value is sign-extended to 32 bits\n
SIGNED: u1 = 0,
/// CROSS_INPUT [16:16]
/// If 1, feed the opposite lane's accumulator into this lane's shift + mask hardware.\n
CROSS_INPUT: u1 = 0,
/// CROSS_RESULT [17:17]
/// If 1, feed the opposite lane's result into this lane's accumulator on POP.
CROSS_RESULT: u1 = 0,
/// ADD_RAW [18:18]
/// If 1, mask + shift is bypassed for LANE0 result. This does not affect FULL result.
ADD_RAW: u1 = 0,
/// FORCE_MSB [19:20]
/// ORed into bits 29:28 of the lane result presented to the processor on the bus.\n
FORCE_MSB: u2 = 0,
/// unused [21:21]
_unused21: u1 = 0,
/// CLAMP [22:22]
/// Only present on INTERP1 on each core. If CLAMP mode is enabled:\n
CLAMP: u1 = 0,
/// OVERF0 [23:23]
/// Indicates if any masked-off MSBs in ACCUM0 are set.
OVERF0: u1 = 0,
/// OVERF1 [24:24]
/// Indicates if any masked-off MSBs in ACCUM1 are set.
OVERF1: u1 = 0,
/// OVERF [25:25]
/// Set if either OVERF0 or OVERF1 is set.
OVERF: u1 = 0,
/// unused [26:31]
_unused26: u6 = 0,
};
/// Control register for lane 0
pub const INTERP1_CTRL_LANE0 = Register(INTERP1_CTRL_LANE0_val).init(base_address + 0xec);

/// INTERP1_PEEK_FULL
const INTERP1_PEEK_FULL_val = packed struct {
INTERP1_PEEK_FULL_0: u8 = 0,
INTERP1_PEEK_FULL_1: u8 = 0,
INTERP1_PEEK_FULL_2: u8 = 0,
INTERP1_PEEK_FULL_3: u8 = 0,
};
/// Read FULL result, without altering any internal state (PEEK).
pub const INTERP1_PEEK_FULL = Register(INTERP1_PEEK_FULL_val).init(base_address + 0xe8);

/// INTERP1_PEEK_LANE1
const INTERP1_PEEK_LANE1_val = packed struct {
INTERP1_PEEK_LANE1_0: u8 = 0,
INTERP1_PEEK_LANE1_1: u8 = 0,
INTERP1_PEEK_LANE1_2: u8 = 0,
INTERP1_PEEK_LANE1_3: u8 = 0,
};
/// Read LANE1 result, without altering any internal state (PEEK).
pub const INTERP1_PEEK_LANE1 = Register(INTERP1_PEEK_LANE1_val).init(base_address + 0xe4);

/// INTERP1_PEEK_LANE0
const INTERP1_PEEK_LANE0_val = packed struct {
INTERP1_PEEK_LANE0_0: u8 = 0,
INTERP1_PEEK_LANE0_1: u8 = 0,
INTERP1_PEEK_LANE0_2: u8 = 0,
INTERP1_PEEK_LANE0_3: u8 = 0,
};
/// Read LANE0 result, without altering any internal state (PEEK).
pub const INTERP1_PEEK_LANE0 = Register(INTERP1_PEEK_LANE0_val).init(base_address + 0xe0);

/// INTERP1_POP_FULL
const INTERP1_POP_FULL_val = packed struct {
INTERP1_POP_FULL_0: u8 = 0,
INTERP1_POP_FULL_1: u8 = 0,
INTERP1_POP_FULL_2: u8 = 0,
INTERP1_POP_FULL_3: u8 = 0,
};
/// Read FULL result, and simultaneously write lane results to both accumulators (POP).
pub const INTERP1_POP_FULL = Register(INTERP1_POP_FULL_val).init(base_address + 0xdc);

/// INTERP1_POP_LANE1
const INTERP1_POP_LANE1_val = packed struct {
INTERP1_POP_LANE1_0: u8 = 0,
INTERP1_POP_LANE1_1: u8 = 0,
INTERP1_POP_LANE1_2: u8 = 0,
INTERP1_POP_LANE1_3: u8 = 0,
};
/// Read LANE1 result, and simultaneously write lane results to both accumulators (POP).
pub const INTERP1_POP_LANE1 = Register(INTERP1_POP_LANE1_val).init(base_address + 0xd8);

/// INTERP1_POP_LANE0
const INTERP1_POP_LANE0_val = packed struct {
INTERP1_POP_LANE0_0: u8 = 0,
INTERP1_POP_LANE0_1: u8 = 0,
INTERP1_POP_LANE0_2: u8 = 0,
INTERP1_POP_LANE0_3: u8 = 0,
};
/// Read LANE0 result, and simultaneously write lane results to both accumulators (POP).
pub const INTERP1_POP_LANE0 = Register(INTERP1_POP_LANE0_val).init(base_address + 0xd4);

/// INTERP1_BASE2
const INTERP1_BASE2_val = packed struct {
INTERP1_BASE2_0: u8 = 0,
INTERP1_BASE2_1: u8 = 0,
INTERP1_BASE2_2: u8 = 0,
INTERP1_BASE2_3: u8 = 0,
};
/// Read/write access to BASE2 register.
pub const INTERP1_BASE2 = Register(INTERP1_BASE2_val).init(base_address + 0xd0);

/// INTERP1_BASE1
const INTERP1_BASE1_val = packed struct {
INTERP1_BASE1_0: u8 = 0,
INTERP1_BASE1_1: u8 = 0,
INTERP1_BASE1_2: u8 = 0,
INTERP1_BASE1_3: u8 = 0,
};
/// Read/write access to BASE1 register.
pub const INTERP1_BASE1 = Register(INTERP1_BASE1_val).init(base_address + 0xcc);

/// INTERP1_BASE0
const INTERP1_BASE0_val = packed struct {
INTERP1_BASE0_0: u8 = 0,
INTERP1_BASE0_1: u8 = 0,
INTERP1_BASE0_2: u8 = 0,
INTERP1_BASE0_3: u8 = 0,
};
/// Read/write access to BASE0 register.
pub const INTERP1_BASE0 = Register(INTERP1_BASE0_val).init(base_address + 0xc8);

/// INTERP1_ACCUM1
const INTERP1_ACCUM1_val = packed struct {
INTERP1_ACCUM1_0: u8 = 0,
INTERP1_ACCUM1_1: u8 = 0,
INTERP1_ACCUM1_2: u8 = 0,
INTERP1_ACCUM1_3: u8 = 0,
};
/// Read/write access to accumulator 1
pub const INTERP1_ACCUM1 = Register(INTERP1_ACCUM1_val).init(base_address + 0xc4);

/// INTERP1_ACCUM0
const INTERP1_ACCUM0_val = packed struct {
INTERP1_ACCUM0_0: u8 = 0,
INTERP1_ACCUM0_1: u8 = 0,
INTERP1_ACCUM0_2: u8 = 0,
INTERP1_ACCUM0_3: u8 = 0,
};
/// Read/write access to accumulator 0
pub const INTERP1_ACCUM0 = Register(INTERP1_ACCUM0_val).init(base_address + 0xc0);

/// INTERP0_BASE_1AND0
const INTERP0_BASE_1AND0_val = packed struct {
INTERP0_BASE_1AND0_0: u8 = 0,
INTERP0_BASE_1AND0_1: u8 = 0,
INTERP0_BASE_1AND0_2: u8 = 0,
INTERP0_BASE_1AND0_3: u8 = 0,
};
/// On write, the lower 16 bits go to BASE0, upper bits to BASE1 simultaneously.\n
pub const INTERP0_BASE_1AND0 = Register(INTERP0_BASE_1AND0_val).init(base_address + 0xbc);

/// INTERP0_ACCUM1_ADD
const INTERP0_ACCUM1_ADD_val = packed struct {
/// INTERP0_ACCUM1_ADD [0:23]
/// No description
INTERP0_ACCUM1_ADD: u24 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// Values written here are atomically added to ACCUM1\n
pub const INTERP0_ACCUM1_ADD = Register(INTERP0_ACCUM1_ADD_val).init(base_address + 0xb8);

/// INTERP0_ACCUM0_ADD
const INTERP0_ACCUM0_ADD_val = packed struct {
/// INTERP0_ACCUM0_ADD [0:23]
/// No description
INTERP0_ACCUM0_ADD: u24 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// Values written here are atomically added to ACCUM0\n
pub const INTERP0_ACCUM0_ADD = Register(INTERP0_ACCUM0_ADD_val).init(base_address + 0xb4);

/// INTERP0_CTRL_LANE1
const INTERP0_CTRL_LANE1_val = packed struct {
/// SHIFT [0:4]
/// Logical right-shift applied to accumulator before masking
SHIFT: u5 = 0,
/// MASK_LSB [5:9]
/// The least-significant bit allowed to pass by the mask (inclusive)
MASK_LSB: u5 = 0,
/// MASK_MSB [10:14]
/// The most-significant bit allowed to pass by the mask (inclusive)\n
MASK_MSB: u5 = 0,
/// SIGNED [15:15]
/// If SIGNED is set, the shifted and masked accumulator value is sign-extended to 32 bits\n
SIGNED: u1 = 0,
/// CROSS_INPUT [16:16]
/// If 1, feed the opposite lane's accumulator into this lane's shift + mask hardware.\n
CROSS_INPUT: u1 = 0,
/// CROSS_RESULT [17:17]
/// If 1, feed the opposite lane's result into this lane's accumulator on POP.
CROSS_RESULT: u1 = 0,
/// ADD_RAW [18:18]
/// If 1, mask + shift is bypassed for LANE1 result. This does not affect FULL result.
ADD_RAW: u1 = 0,
/// FORCE_MSB [19:20]
/// ORed into bits 29:28 of the lane result presented to the processor on the bus.\n
FORCE_MSB: u2 = 0,
/// unused [21:31]
_unused21: u3 = 0,
_unused24: u8 = 0,
};
/// Control register for lane 1
pub const INTERP0_CTRL_LANE1 = Register(INTERP0_CTRL_LANE1_val).init(base_address + 0xb0);

/// INTERP0_CTRL_LANE0
const INTERP0_CTRL_LANE0_val = packed struct {
/// SHIFT [0:4]
/// Logical right-shift applied to accumulator before masking
SHIFT: u5 = 0,
/// MASK_LSB [5:9]
/// The least-significant bit allowed to pass by the mask (inclusive)
MASK_LSB: u5 = 0,
/// MASK_MSB [10:14]
/// The most-significant bit allowed to pass by the mask (inclusive)\n
MASK_MSB: u5 = 0,
/// SIGNED [15:15]
/// If SIGNED is set, the shifted and masked accumulator value is sign-extended to 32 bits\n
SIGNED: u1 = 0,
/// CROSS_INPUT [16:16]
/// If 1, feed the opposite lane's accumulator into this lane's shift + mask hardware.\n
CROSS_INPUT: u1 = 0,
/// CROSS_RESULT [17:17]
/// If 1, feed the opposite lane's result into this lane's accumulator on POP.
CROSS_RESULT: u1 = 0,
/// ADD_RAW [18:18]
/// If 1, mask + shift is bypassed for LANE0 result. This does not affect FULL result.
ADD_RAW: u1 = 0,
/// FORCE_MSB [19:20]
/// ORed into bits 29:28 of the lane result presented to the processor on the bus.\n
FORCE_MSB: u2 = 0,
/// BLEND [21:21]
/// Only present on INTERP0 on each core. If BLEND mode is enabled:\n
BLEND: u1 = 0,
/// unused [22:22]
_unused22: u1 = 0,
/// OVERF0 [23:23]
/// Indicates if any masked-off MSBs in ACCUM0 are set.
OVERF0: u1 = 0,
/// OVERF1 [24:24]
/// Indicates if any masked-off MSBs in ACCUM1 are set.
OVERF1: u1 = 0,
/// OVERF [25:25]
/// Set if either OVERF0 or OVERF1 is set.
OVERF: u1 = 0,
/// unused [26:31]
_unused26: u6 = 0,
};
/// Control register for lane 0
pub const INTERP0_CTRL_LANE0 = Register(INTERP0_CTRL_LANE0_val).init(base_address + 0xac);

/// INTERP0_PEEK_FULL
const INTERP0_PEEK_FULL_val = packed struct {
INTERP0_PEEK_FULL_0: u8 = 0,
INTERP0_PEEK_FULL_1: u8 = 0,
INTERP0_PEEK_FULL_2: u8 = 0,
INTERP0_PEEK_FULL_3: u8 = 0,
};
/// Read FULL result, without altering any internal state (PEEK).
pub const INTERP0_PEEK_FULL = Register(INTERP0_PEEK_FULL_val).init(base_address + 0xa8);

/// INTERP0_PEEK_LANE1
const INTERP0_PEEK_LANE1_val = packed struct {
INTERP0_PEEK_LANE1_0: u8 = 0,
INTERP0_PEEK_LANE1_1: u8 = 0,
INTERP0_PEEK_LANE1_2: u8 = 0,
INTERP0_PEEK_LANE1_3: u8 = 0,
};
/// Read LANE1 result, without altering any internal state (PEEK).
pub const INTERP0_PEEK_LANE1 = Register(INTERP0_PEEK_LANE1_val).init(base_address + 0xa4);

/// INTERP0_PEEK_LANE0
const INTERP0_PEEK_LANE0_val = packed struct {
INTERP0_PEEK_LANE0_0: u8 = 0,
INTERP0_PEEK_LANE0_1: u8 = 0,
INTERP0_PEEK_LANE0_2: u8 = 0,
INTERP0_PEEK_LANE0_3: u8 = 0,
};
/// Read LANE0 result, without altering any internal state (PEEK).
pub const INTERP0_PEEK_LANE0 = Register(INTERP0_PEEK_LANE0_val).init(base_address + 0xa0);

/// INTERP0_POP_FULL
const INTERP0_POP_FULL_val = packed struct {
INTERP0_POP_FULL_0: u8 = 0,
INTERP0_POP_FULL_1: u8 = 0,
INTERP0_POP_FULL_2: u8 = 0,
INTERP0_POP_FULL_3: u8 = 0,
};
/// Read FULL result, and simultaneously write lane results to both accumulators (POP).
pub const INTERP0_POP_FULL = Register(INTERP0_POP_FULL_val).init(base_address + 0x9c);

/// INTERP0_POP_LANE1
const INTERP0_POP_LANE1_val = packed struct {
INTERP0_POP_LANE1_0: u8 = 0,
INTERP0_POP_LANE1_1: u8 = 0,
INTERP0_POP_LANE1_2: u8 = 0,
INTERP0_POP_LANE1_3: u8 = 0,
};
/// Read LANE1 result, and simultaneously write lane results to both accumulators (POP).
pub const INTERP0_POP_LANE1 = Register(INTERP0_POP_LANE1_val).init(base_address + 0x98);

/// INTERP0_POP_LANE0
const INTERP0_POP_LANE0_val = packed struct {
INTERP0_POP_LANE0_0: u8 = 0,
INTERP0_POP_LANE0_1: u8 = 0,
INTERP0_POP_LANE0_2: u8 = 0,
INTERP0_POP_LANE0_3: u8 = 0,
};
/// Read LANE0 result, and simultaneously write lane results to both accumulators (POP).
pub const INTERP0_POP_LANE0 = Register(INTERP0_POP_LANE0_val).init(base_address + 0x94);

/// INTERP0_BASE2
const INTERP0_BASE2_val = packed struct {
INTERP0_BASE2_0: u8 = 0,
INTERP0_BASE2_1: u8 = 0,
INTERP0_BASE2_2: u8 = 0,
INTERP0_BASE2_3: u8 = 0,
};
/// Read/write access to BASE2 register.
pub const INTERP0_BASE2 = Register(INTERP0_BASE2_val).init(base_address + 0x90);

/// INTERP0_BASE1
const INTERP0_BASE1_val = packed struct {
INTERP0_BASE1_0: u8 = 0,
INTERP0_BASE1_1: u8 = 0,
INTERP0_BASE1_2: u8 = 0,
INTERP0_BASE1_3: u8 = 0,
};
/// Read/write access to BASE1 register.
pub const INTERP0_BASE1 = Register(INTERP0_BASE1_val).init(base_address + 0x8c);

/// INTERP0_BASE0
const INTERP0_BASE0_val = packed struct {
INTERP0_BASE0_0: u8 = 0,
INTERP0_BASE0_1: u8 = 0,
INTERP0_BASE0_2: u8 = 0,
INTERP0_BASE0_3: u8 = 0,
};
/// Read/write access to BASE0 register.
pub const INTERP0_BASE0 = Register(INTERP0_BASE0_val).init(base_address + 0x88);

/// INTERP0_ACCUM1
const INTERP0_ACCUM1_val = packed struct {
INTERP0_ACCUM1_0: u8 = 0,
INTERP0_ACCUM1_1: u8 = 0,
INTERP0_ACCUM1_2: u8 = 0,
INTERP0_ACCUM1_3: u8 = 0,
};
/// Read/write access to accumulator 1
pub const INTERP0_ACCUM1 = Register(INTERP0_ACCUM1_val).init(base_address + 0x84);

/// INTERP0_ACCUM0
const INTERP0_ACCUM0_val = packed struct {
INTERP0_ACCUM0_0: u8 = 0,
INTERP0_ACCUM0_1: u8 = 0,
INTERP0_ACCUM0_2: u8 = 0,
INTERP0_ACCUM0_3: u8 = 0,
};
/// Read/write access to accumulator 0
pub const INTERP0_ACCUM0 = Register(INTERP0_ACCUM0_val).init(base_address + 0x80);

/// DIV_CSR
const DIV_CSR_val = packed struct {
/// READY [0:0]
/// Reads as 0 when a calculation is in progress, 1 otherwise.\n
READY: u1 = 1,
/// DIRTY [1:1]
/// Changes to 1 when any register is written, and back to 0 when QUOTIENT is read.\n
DIRTY: u1 = 0,
/// unused [2:31]
_unused2: u6 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Control and status register for divider.
pub const DIV_CSR = Register(DIV_CSR_val).init(base_address + 0x78);

/// DIV_REMAINDER
const DIV_REMAINDER_val = packed struct {
DIV_REMAINDER_0: u8 = 0,
DIV_REMAINDER_1: u8 = 0,
DIV_REMAINDER_2: u8 = 0,
DIV_REMAINDER_3: u8 = 0,
};
/// Divider result remainder\n
pub const DIV_REMAINDER = Register(DIV_REMAINDER_val).init(base_address + 0x74);

/// DIV_QUOTIENT
const DIV_QUOTIENT_val = packed struct {
DIV_QUOTIENT_0: u8 = 0,
DIV_QUOTIENT_1: u8 = 0,
DIV_QUOTIENT_2: u8 = 0,
DIV_QUOTIENT_3: u8 = 0,
};
/// Divider result quotient\n
pub const DIV_QUOTIENT = Register(DIV_QUOTIENT_val).init(base_address + 0x70);

/// DIV_SDIVISOR
const DIV_SDIVISOR_val = packed struct {
DIV_SDIVISOR_0: u8 = 0,
DIV_SDIVISOR_1: u8 = 0,
DIV_SDIVISOR_2: u8 = 0,
DIV_SDIVISOR_3: u8 = 0,
};
/// Divider signed divisor\n
pub const DIV_SDIVISOR = Register(DIV_SDIVISOR_val).init(base_address + 0x6c);

/// DIV_SDIVIDEND
const DIV_SDIVIDEND_val = packed struct {
DIV_SDIVIDEND_0: u8 = 0,
DIV_SDIVIDEND_1: u8 = 0,
DIV_SDIVIDEND_2: u8 = 0,
DIV_SDIVIDEND_3: u8 = 0,
};
/// Divider signed dividend\n
pub const DIV_SDIVIDEND = Register(DIV_SDIVIDEND_val).init(base_address + 0x68);

/// DIV_UDIVISOR
const DIV_UDIVISOR_val = packed struct {
DIV_UDIVISOR_0: u8 = 0,
DIV_UDIVISOR_1: u8 = 0,
DIV_UDIVISOR_2: u8 = 0,
DIV_UDIVISOR_3: u8 = 0,
};
/// Divider unsigned divisor\n
pub const DIV_UDIVISOR = Register(DIV_UDIVISOR_val).init(base_address + 0x64);

/// DIV_UDIVIDEND
const DIV_UDIVIDEND_val = packed struct {
DIV_UDIVIDEND_0: u8 = 0,
DIV_UDIVIDEND_1: u8 = 0,
DIV_UDIVIDEND_2: u8 = 0,
DIV_UDIVIDEND_3: u8 = 0,
};
/// Divider unsigned dividend\n
pub const DIV_UDIVIDEND = Register(DIV_UDIVIDEND_val).init(base_address + 0x60);

/// SPINLOCK_ST
const SPINLOCK_ST_val = packed struct {
SPINLOCK_ST_0: u8 = 0,
SPINLOCK_ST_1: u8 = 0,
SPINLOCK_ST_2: u8 = 0,
SPINLOCK_ST_3: u8 = 0,
};
/// Spinlock state\n
pub const SPINLOCK_ST = Register(SPINLOCK_ST_val).init(base_address + 0x5c);

/// FIFO_RD
const FIFO_RD_val = packed struct {
FIFO_RD_0: u8 = 0,
FIFO_RD_1: u8 = 0,
FIFO_RD_2: u8 = 0,
FIFO_RD_3: u8 = 0,
};
/// Read access to this core's RX FIFO
pub const FIFO_RD = Register(FIFO_RD_val).init(base_address + 0x58);

/// FIFO_WR
const FIFO_WR_val = packed struct {
FIFO_WR_0: u8 = 0,
FIFO_WR_1: u8 = 0,
FIFO_WR_2: u8 = 0,
FIFO_WR_3: u8 = 0,
};
/// Write access to this core's TX FIFO
pub const FIFO_WR = Register(FIFO_WR_val).init(base_address + 0x54);

/// FIFO_ST
const FIFO_ST_val = packed struct {
/// VLD [0:0]
/// Value is 1 if this core's RX FIFO is not empty (i.e. if FIFO_RD is valid)
VLD: u1 = 0,
/// RDY [1:1]
/// Value is 1 if this core's TX FIFO is not full (i.e. if FIFO_WR is ready for more data)
RDY: u1 = 1,
/// WOF [2:2]
/// Sticky flag indicating the TX FIFO was written when full. This write was ignored by the FIFO.
WOF: u1 = 0,
/// ROE [3:3]
/// Sticky flag indicating the RX FIFO was read when empty. This read was ignored by the FIFO.
ROE: u1 = 0,
/// unused [4:31]
_unused4: u4 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Status register for inter-core FIFOs (mailboxes).\n
pub const FIFO_ST = Register(FIFO_ST_val).init(base_address + 0x50);

/// GPIO_HI_OE_XOR
const GPIO_HI_OE_XOR_val = packed struct {
/// GPIO_HI_OE_XOR [0:5]
/// Perform an atomic bitwise XOR on GPIO_HI_OE, i.e. `GPIO_HI_OE ^= wdata`
GPIO_HI_OE_XOR: u6 = 0,
/// unused [6:31]
_unused6: u2 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// QSPI output enable XOR
pub const GPIO_HI_OE_XOR = Register(GPIO_HI_OE_XOR_val).init(base_address + 0x4c);

/// GPIO_HI_OE_CLR
const GPIO_HI_OE_CLR_val = packed struct {
/// GPIO_HI_OE_CLR [0:5]
/// Perform an atomic bit-clear on GPIO_HI_OE, i.e. `GPIO_HI_OE &amp;= ~wdata`
GPIO_HI_OE_CLR: u6 = 0,
/// unused [6:31]
_unused6: u2 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// QSPI output enable clear
pub const GPIO_HI_OE_CLR = Register(GPIO_HI_OE_CLR_val).init(base_address + 0x48);

/// GPIO_HI_OE_SET
const GPIO_HI_OE_SET_val = packed struct {
/// GPIO_HI_OE_SET [0:5]
/// Perform an atomic bit-set on GPIO_HI_OE, i.e. `GPIO_HI_OE |= wdata`
GPIO_HI_OE_SET: u6 = 0,
/// unused [6:31]
_unused6: u2 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// QSPI output enable set
pub const GPIO_HI_OE_SET = Register(GPIO_HI_OE_SET_val).init(base_address + 0x44);

/// GPIO_HI_OE
const GPIO_HI_OE_val = packed struct {
/// GPIO_HI_OE [0:5]
/// Set output enable (1/0 -&gt; output/input) for QSPI IO0...5.\n
GPIO_HI_OE: u6 = 0,
/// unused [6:31]
_unused6: u2 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// QSPI output enable
pub const GPIO_HI_OE = Register(GPIO_HI_OE_val).init(base_address + 0x40);

/// GPIO_HI_OUT_XOR
const GPIO_HI_OUT_XOR_val = packed struct {
/// GPIO_HI_OUT_XOR [0:5]
/// Perform an atomic bitwise XOR on GPIO_HI_OUT, i.e. `GPIO_HI_OUT ^= wdata`
GPIO_HI_OUT_XOR: u6 = 0,
/// unused [6:31]
_unused6: u2 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// QSPI output value XOR
pub const GPIO_HI_OUT_XOR = Register(GPIO_HI_OUT_XOR_val).init(base_address + 0x3c);

/// GPIO_HI_OUT_CLR
const GPIO_HI_OUT_CLR_val = packed struct {
/// GPIO_HI_OUT_CLR [0:5]
/// Perform an atomic bit-clear on GPIO_HI_OUT, i.e. `GPIO_HI_OUT &amp;= ~wdata`
GPIO_HI_OUT_CLR: u6 = 0,
/// unused [6:31]
_unused6: u2 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// QSPI output value clear
pub const GPIO_HI_OUT_CLR = Register(GPIO_HI_OUT_CLR_val).init(base_address + 0x38);

/// GPIO_HI_OUT_SET
const GPIO_HI_OUT_SET_val = packed struct {
/// GPIO_HI_OUT_SET [0:5]
/// Perform an atomic bit-set on GPIO_HI_OUT, i.e. `GPIO_HI_OUT |= wdata`
GPIO_HI_OUT_SET: u6 = 0,
/// unused [6:31]
_unused6: u2 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// QSPI output value set
pub const GPIO_HI_OUT_SET = Register(GPIO_HI_OUT_SET_val).init(base_address + 0x34);

/// GPIO_HI_OUT
const GPIO_HI_OUT_val = packed struct {
/// GPIO_HI_OUT [0:5]
/// Set output level (1/0 -&gt; high/low) for QSPI IO0...5.\n
GPIO_HI_OUT: u6 = 0,
/// unused [6:31]
_unused6: u2 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// QSPI output value
pub const GPIO_HI_OUT = Register(GPIO_HI_OUT_val).init(base_address + 0x30);

/// GPIO_OE_XOR
const GPIO_OE_XOR_val = packed struct {
/// GPIO_OE_XOR [0:29]
/// Perform an atomic bitwise XOR on GPIO_OE, i.e. `GPIO_OE ^= wdata`
GPIO_OE_XOR: u30 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// GPIO output enable XOR
pub const GPIO_OE_XOR = Register(GPIO_OE_XOR_val).init(base_address + 0x2c);

/// GPIO_OE_CLR
const GPIO_OE_CLR_val = packed struct {
/// GPIO_OE_CLR [0:29]
/// Perform an atomic bit-clear on GPIO_OE, i.e. `GPIO_OE &amp;= ~wdata`
GPIO_OE_CLR: u30 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// GPIO output enable clear
pub const GPIO_OE_CLR = Register(GPIO_OE_CLR_val).init(base_address + 0x28);

/// GPIO_OE_SET
const GPIO_OE_SET_val = packed struct {
/// GPIO_OE_SET [0:29]
/// Perform an atomic bit-set on GPIO_OE, i.e. `GPIO_OE |= wdata`
GPIO_OE_SET: u30 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// GPIO output enable set
pub const GPIO_OE_SET = Register(GPIO_OE_SET_val).init(base_address + 0x24);

/// GPIO_OE
const GPIO_OE_val = packed struct {
/// GPIO_OE [0:29]
/// Set output enable (1/0 -&gt; output/input) for GPIO0...29.\n
GPIO_OE: u30 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// GPIO output enable
pub const GPIO_OE = Register(GPIO_OE_val).init(base_address + 0x20);

/// GPIO_OUT_XOR
const GPIO_OUT_XOR_val = packed struct {
/// GPIO_OUT_XOR [0:29]
/// Perform an atomic bitwise XOR on GPIO_OUT, i.e. `GPIO_OUT ^= wdata`
GPIO_OUT_XOR: u30 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// GPIO output value XOR
pub const GPIO_OUT_XOR = Register(GPIO_OUT_XOR_val).init(base_address + 0x1c);

/// GPIO_OUT_CLR
const GPIO_OUT_CLR_val = packed struct {
/// GPIO_OUT_CLR [0:29]
/// Perform an atomic bit-clear on GPIO_OUT, i.e. `GPIO_OUT &amp;= ~wdata`
GPIO_OUT_CLR: u30 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// GPIO output value clear
pub const GPIO_OUT_CLR = Register(GPIO_OUT_CLR_val).init(base_address + 0x18);

/// GPIO_OUT_SET
const GPIO_OUT_SET_val = packed struct {
/// GPIO_OUT_SET [0:29]
/// Perform an atomic bit-set on GPIO_OUT, i.e. `GPIO_OUT |= wdata`
GPIO_OUT_SET: u30 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// GPIO output value set
pub const GPIO_OUT_SET = Register(GPIO_OUT_SET_val).init(base_address + 0x14);

/// GPIO_OUT
const GPIO_OUT_val = packed struct {
/// GPIO_OUT [0:29]
/// Set output level (1/0 -&gt; high/low) for GPIO0...29.\n
GPIO_OUT: u30 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// GPIO output value
pub const GPIO_OUT = Register(GPIO_OUT_val).init(base_address + 0x10);

/// GPIO_HI_IN
const GPIO_HI_IN_val = packed struct {
/// GPIO_HI_IN [0:5]
/// Input value on QSPI IO in order 0..5: SCLK, SSn, SD0, SD1, SD2, SD3
GPIO_HI_IN: u6 = 0,
/// unused [6:31]
_unused6: u2 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Input value for QSPI pins
pub const GPIO_HI_IN = Register(GPIO_HI_IN_val).init(base_address + 0x8);

/// GPIO_IN
const GPIO_IN_val = packed struct {
/// GPIO_IN [0:29]
/// Input value for GPIO0...29
GPIO_IN: u30 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// Input value for GPIO pins
pub const GPIO_IN = Register(GPIO_IN_val).init(base_address + 0x4);

/// CPUID
const CPUID_val = packed struct {
CPUID_0: u8 = 0,
CPUID_1: u8 = 0,
CPUID_2: u8 = 0,
CPUID_3: u8 = 0,
};
/// Processor core identifier\n
pub const CPUID = Register(CPUID_val).init(base_address + 0x0);
};

/// No description
pub const PPB = struct {

const base_address = 0xe0000000;
/// MPU_RASR
const MPU_RASR_val = packed struct {
/// ENABLE [0:0]
/// Enables the region.
ENABLE: u1 = 0,
/// SIZE [1:5]
/// Indicates the region size. Region size in bytes = 2^(SIZE+1). The minimum permitted value is 7 (b00111) = 256Bytes
SIZE: u5 = 0,
/// unused [6:7]
_unused6: u2 = 0,
/// SRD [8:15]
/// Subregion Disable. For regions of 256 bytes or larger, each bit of this field controls whether one of the eight equal subregions is enabled.
SRD: u8 = 0,
/// ATTRS [16:31]
/// The MPU Region Attribute field. Use to define the region attribute control.\n
ATTRS: u16 = 0,
};
/// Use the MPU Region Attribute and Size Register to define the size, access behaviour and memory type of the region identified by MPU_RNR, and enable that region.
pub const MPU_RASR = Register(MPU_RASR_val).init(base_address + 0xeda0);

/// MPU_RBAR
const MPU_RBAR_val = packed struct {
/// REGION [0:3]
/// On writes, specifies the number of the region whose base address to update provided VALID is set written as 1. On reads, returns bits [3:0] of MPU_RNR.
REGION: u4 = 0,
/// VALID [4:4]
/// On writes, indicates whether the write must update the base address of the region identified by the REGION field, updating the MPU_RNR to indicate this new region.\n
VALID: u1 = 0,
/// unused [5:7]
_unused5: u3 = 0,
/// ADDR [8:31]
/// Base address of the region.
ADDR: u24 = 0,
};
/// Read the MPU Region Base Address Register to determine the base address of the region identified by MPU_RNR. Write to update the base address of said region or that of a specified region, with whose number MPU_RNR will also be updated.
pub const MPU_RBAR = Register(MPU_RBAR_val).init(base_address + 0xed9c);

/// MPU_RNR
const MPU_RNR_val = packed struct {
/// REGION [0:3]
/// Indicates the MPU region referenced by the MPU_RBAR and MPU_RASR registers.\n
REGION: u4 = 0,
/// unused [4:31]
_unused4: u4 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Use the MPU Region Number Register to select the region currently accessed by MPU_RBAR and MPU_RASR.
pub const MPU_RNR = Register(MPU_RNR_val).init(base_address + 0xed98);

/// MPU_CTRL
const MPU_CTRL_val = packed struct {
/// ENABLE [0:0]
/// Enables the MPU. If the MPU is disabled, privileged and unprivileged accesses use the default memory map.\n
ENABLE: u1 = 0,
/// HFNMIENA [1:1]
/// Controls the use of the MPU for HardFaults and NMIs. Setting this bit when ENABLE is clear results in UNPREDICTABLE behaviour.\n
HFNMIENA: u1 = 0,
/// PRIVDEFENA [2:2]
/// Controls whether the default memory map is enabled as a background region for privileged accesses. This bit is ignored when ENABLE is clear.\n
PRIVDEFENA: u1 = 0,
/// unused [3:31]
_unused3: u5 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Use the MPU Control Register to enable and disable the MPU, and to control whether the default memory map is enabled as a background region for privileged accesses, and whether the MPU is enabled for HardFaults and NMIs.
pub const MPU_CTRL = Register(MPU_CTRL_val).init(base_address + 0xed94);

/// MPU_TYPE
const MPU_TYPE_val = packed struct {
/// SEPARATE [0:0]
/// Indicates support for separate instruction and data address maps. Reads as 0 as ARMv6-M only supports a unified MPU.
SEPARATE: u1 = 0,
/// unused [1:7]
_unused1: u7 = 0,
/// DREGION [8:15]
/// Number of regions supported by the MPU.
DREGION: u8 = 8,
/// IREGION [16:23]
/// Instruction region. Reads as zero as ARMv6-M only supports a unified MPU.
IREGION: u8 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// Read the MPU Type Register to determine if the processor implements an MPU, and how many regions the MPU supports.
pub const MPU_TYPE = Register(MPU_TYPE_val).init(base_address + 0xed90);

/// SHCSR
const SHCSR_val = packed struct {
/// unused [0:14]
_unused0: u8 = 0,
_unused8: u7 = 0,
/// SVCALLPENDED [15:15]
/// Reads as 1 if SVCall is Pending.  Write 1 to set pending SVCall, write 0 to clear pending SVCall.
SVCALLPENDED: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Use the System Handler Control and State Register to determine or clear the pending status of SVCall.
pub const SHCSR = Register(SHCSR_val).init(base_address + 0xed24);

/// SHPR3
const SHPR3_val = packed struct {
/// unused [0:21]
_unused0: u8 = 0,
_unused8: u8 = 0,
_unused16: u6 = 0,
/// PRI_14 [22:23]
/// Priority of system handler 14, PendSV
PRI_14: u2 = 0,
/// unused [24:29]
_unused24: u6 = 0,
/// PRI_15 [30:31]
/// Priority of system handler 15, SysTick
PRI_15: u2 = 0,
};
/// System handlers are a special class of exception handler that can have their priority set to any of the priority levels. Use the System Handler Priority Register 3 to set the priority of PendSV and SysTick.
pub const SHPR3 = Register(SHPR3_val).init(base_address + 0xed20);

/// SHPR2
const SHPR2_val = packed struct {
/// unused [0:29]
_unused0: u8 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u6 = 0,
/// PRI_11 [30:31]
/// Priority of system handler 11, SVCall
PRI_11: u2 = 0,
};
/// System handlers are a special class of exception handler that can have their priority set to any of the priority levels. Use the System Handler Priority Register 2 to set the priority of SVCall.
pub const SHPR2 = Register(SHPR2_val).init(base_address + 0xed1c);

/// CCR
const CCR_val = packed struct {
/// unused [0:2]
_unused0: u3 = 0,
/// UNALIGN_TRP [3:3]
/// Always reads as one, indicates that all unaligned accesses generate a HardFault.
UNALIGN_TRP: u1 = 0,
/// unused [4:8]
_unused4: u4 = 0,
_unused8: u1 = 0,
/// STKALIGN [9:9]
/// Always reads as one, indicates 8-byte stack alignment on exception entry. On exception entry, the processor uses bit[9] of the stacked PSR to indicate the stack alignment. On return from the exception it uses this stacked bit to restore the correct stack alignment.
STKALIGN: u1 = 0,
/// unused [10:31]
_unused10: u6 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// The Configuration and Control Register permanently enables stack alignment and causes unaligned accesses to result in a Hard Fault.
pub const CCR = Register(CCR_val).init(base_address + 0xed14);

/// SCR
const SCR_val = packed struct {
/// unused [0:0]
_unused0: u1 = 0,
/// SLEEPONEXIT [1:1]
/// Indicates sleep-on-exit when returning from Handler mode to Thread mode:\n
SLEEPONEXIT: u1 = 0,
/// SLEEPDEEP [2:2]
/// Controls whether the processor uses sleep or deep sleep as its low power mode:\n
SLEEPDEEP: u1 = 0,
/// unused [3:3]
_unused3: u1 = 0,
/// SEVONPEND [4:4]
/// Send Event on Pending bit:\n
SEVONPEND: u1 = 0,
/// unused [5:31]
_unused5: u3 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// System Control Register. Use the System Control Register for power-management functions: signal to the system when the processor can enter a low power state, control how the processor enters and exits low power states.
pub const SCR = Register(SCR_val).init(base_address + 0xed10);

/// AIRCR
const AIRCR_val = packed struct {
/// unused [0:0]
_unused0: u1 = 0,
/// VECTCLRACTIVE [1:1]
/// Clears all active state information for fixed and configurable exceptions. This bit: is self-clearing, can only be set by the DAP when the core is halted.  When set: clears all active exception status of the processor, forces a return to Thread mode, forces an IPSR of 0. A debugger must re-initialize the stack.
VECTCLRACTIVE: u1 = 0,
/// SYSRESETREQ [2:2]
/// Writing 1 to this bit causes the SYSRESETREQ signal to the outer system to be asserted to request a reset. The intention is to force a large system reset of all major components except for debug. The C_HALT bit in the DHCSR is cleared as a result of the system reset requested. The debugger does not lose contact with the device.
SYSRESETREQ: u1 = 0,
/// unused [3:14]
_unused3: u5 = 0,
_unused8: u7 = 0,
/// ENDIANESS [15:15]
/// Data endianness implemented:\n
ENDIANESS: u1 = 0,
/// VECTKEY [16:31]
/// Register key:\n
VECTKEY: u16 = 0,
};
/// Use the Application Interrupt and Reset Control Register to: determine data endianness, clear all active state information from debug halt mode, request a system reset.
pub const AIRCR = Register(AIRCR_val).init(base_address + 0xed0c);

/// VTOR
const VTOR_val = packed struct {
/// unused [0:7]
_unused0: u8 = 0,
/// TBLOFF [8:31]
/// Bits [31:8] of the indicate the vector table offset address.
TBLOFF: u24 = 0,
};
/// The VTOR holds the vector table offset address.
pub const VTOR = Register(VTOR_val).init(base_address + 0xed08);

/// ICSR
const ICSR_val = packed struct {
/// VECTACTIVE [0:8]
/// Active exception number field. Reset clears the VECTACTIVE field.
VECTACTIVE: u9 = 0,
/// unused [9:11]
_unused9: u3 = 0,
/// VECTPENDING [12:20]
/// Indicates the exception number for the highest priority pending exception: 0 = no pending exceptions. Non zero = The pending state includes the effect of memory-mapped enable and mask registers. It does not include the PRIMASK special-purpose register qualifier.
VECTPENDING: u9 = 0,
/// unused [21:21]
_unused21: u1 = 0,
/// ISRPENDING [22:22]
/// External interrupt pending flag
ISRPENDING: u1 = 0,
/// ISRPREEMPT [23:23]
/// The system can only access this bit when the core is halted. It indicates that a pending interrupt is to be taken in the next running cycle. If C_MASKINTS is clear in the Debug Halting Control and Status Register, the interrupt is serviced.
ISRPREEMPT: u1 = 0,
/// unused [24:24]
_unused24: u1 = 0,
/// PENDSTCLR [25:25]
/// SysTick exception clear-pending bit.\n
PENDSTCLR: u1 = 0,
/// PENDSTSET [26:26]
/// SysTick exception set-pending bit.\n
PENDSTSET: u1 = 0,
/// PENDSVCLR [27:27]
/// PendSV clear-pending bit.\n
PENDSVCLR: u1 = 0,
/// PENDSVSET [28:28]
/// PendSV set-pending bit.\n
PENDSVSET: u1 = 0,
/// unused [29:30]
_unused29: u2 = 0,
/// NMIPENDSET [31:31]
/// Setting this bit will activate an NMI. Since NMI is the highest priority exception, it will activate as soon as it is registered.\n
NMIPENDSET: u1 = 0,
};
/// Use the Interrupt Control State Register to set a pending Non-Maskable Interrupt (NMI), set or clear a pending PendSV, set or clear a pending SysTick, check for pending exceptions, check the vector number of the highest priority pended exception, check the vector number of the active exception.
pub const ICSR = Register(ICSR_val).init(base_address + 0xed04);

/// CPUID
const CPUID_val = packed struct {
/// REVISION [0:3]
/// Minor revision number m in the rnpm revision status:\n
REVISION: u4 = 1,
/// PARTNO [4:15]
/// Number of processor within family: 0xC60 = Cortex-M0+
PARTNO: u12 = 3168,
/// ARCHITECTURE [16:19]
/// Constant that defines the architecture of the processor:\n
ARCHITECTURE: u4 = 12,
/// VARIANT [20:23]
/// Major revision number n in the rnpm revision status:\n
VARIANT: u4 = 0,
/// IMPLEMENTER [24:31]
/// Implementor code: 0x41 = ARM
IMPLEMENTER: u8 = 65,
};
/// Read the CPU ID Base Register to determine: the ID number of the processor core, the version number of the processor core, the implementation details of the processor core.
pub const CPUID = Register(CPUID_val).init(base_address + 0xed00);

/// NVIC_IPR7
const NVIC_IPR7_val = packed struct {
/// unused [0:5]
_unused0: u6 = 0,
/// IP_28 [6:7]
/// Priority of interrupt 28
IP_28: u2 = 0,
/// unused [8:13]
_unused8: u6 = 0,
/// IP_29 [14:15]
/// Priority of interrupt 29
IP_29: u2 = 0,
/// unused [16:21]
_unused16: u6 = 0,
/// IP_30 [22:23]
/// Priority of interrupt 30
IP_30: u2 = 0,
/// unused [24:29]
_unused24: u6 = 0,
/// IP_31 [30:31]
/// Priority of interrupt 31
IP_31: u2 = 0,
};
/// Use the Interrupt Priority Registers to assign a priority from 0 to 3 to each of the available interrupts. 0 is the highest priority, and 3 is the lowest.
pub const NVIC_IPR7 = Register(NVIC_IPR7_val).init(base_address + 0xe41c);

/// NVIC_IPR6
const NVIC_IPR6_val = packed struct {
/// unused [0:5]
_unused0: u6 = 0,
/// IP_24 [6:7]
/// Priority of interrupt 24
IP_24: u2 = 0,
/// unused [8:13]
_unused8: u6 = 0,
/// IP_25 [14:15]
/// Priority of interrupt 25
IP_25: u2 = 0,
/// unused [16:21]
_unused16: u6 = 0,
/// IP_26 [22:23]
/// Priority of interrupt 26
IP_26: u2 = 0,
/// unused [24:29]
_unused24: u6 = 0,
/// IP_27 [30:31]
/// Priority of interrupt 27
IP_27: u2 = 0,
};
/// Use the Interrupt Priority Registers to assign a priority from 0 to 3 to each of the available interrupts. 0 is the highest priority, and 3 is the lowest.
pub const NVIC_IPR6 = Register(NVIC_IPR6_val).init(base_address + 0xe418);

/// NVIC_IPR5
const NVIC_IPR5_val = packed struct {
/// unused [0:5]
_unused0: u6 = 0,
/// IP_20 [6:7]
/// Priority of interrupt 20
IP_20: u2 = 0,
/// unused [8:13]
_unused8: u6 = 0,
/// IP_21 [14:15]
/// Priority of interrupt 21
IP_21: u2 = 0,
/// unused [16:21]
_unused16: u6 = 0,
/// IP_22 [22:23]
/// Priority of interrupt 22
IP_22: u2 = 0,
/// unused [24:29]
_unused24: u6 = 0,
/// IP_23 [30:31]
/// Priority of interrupt 23
IP_23: u2 = 0,
};
/// Use the Interrupt Priority Registers to assign a priority from 0 to 3 to each of the available interrupts. 0 is the highest priority, and 3 is the lowest.
pub const NVIC_IPR5 = Register(NVIC_IPR5_val).init(base_address + 0xe414);

/// NVIC_IPR4
const NVIC_IPR4_val = packed struct {
/// unused [0:5]
_unused0: u6 = 0,
/// IP_16 [6:7]
/// Priority of interrupt 16
IP_16: u2 = 0,
/// unused [8:13]
_unused8: u6 = 0,
/// IP_17 [14:15]
/// Priority of interrupt 17
IP_17: u2 = 0,
/// unused [16:21]
_unused16: u6 = 0,
/// IP_18 [22:23]
/// Priority of interrupt 18
IP_18: u2 = 0,
/// unused [24:29]
_unused24: u6 = 0,
/// IP_19 [30:31]
/// Priority of interrupt 19
IP_19: u2 = 0,
};
/// Use the Interrupt Priority Registers to assign a priority from 0 to 3 to each of the available interrupts. 0 is the highest priority, and 3 is the lowest.
pub const NVIC_IPR4 = Register(NVIC_IPR4_val).init(base_address + 0xe410);

/// NVIC_IPR3
const NVIC_IPR3_val = packed struct {
/// unused [0:5]
_unused0: u6 = 0,
/// IP_12 [6:7]
/// Priority of interrupt 12
IP_12: u2 = 0,
/// unused [8:13]
_unused8: u6 = 0,
/// IP_13 [14:15]
/// Priority of interrupt 13
IP_13: u2 = 0,
/// unused [16:21]
_unused16: u6 = 0,
/// IP_14 [22:23]
/// Priority of interrupt 14
IP_14: u2 = 0,
/// unused [24:29]
_unused24: u6 = 0,
/// IP_15 [30:31]
/// Priority of interrupt 15
IP_15: u2 = 0,
};
/// Use the Interrupt Priority Registers to assign a priority from 0 to 3 to each of the available interrupts. 0 is the highest priority, and 3 is the lowest.
pub const NVIC_IPR3 = Register(NVIC_IPR3_val).init(base_address + 0xe40c);

/// NVIC_IPR2
const NVIC_IPR2_val = packed struct {
/// unused [0:5]
_unused0: u6 = 0,
/// IP_8 [6:7]
/// Priority of interrupt 8
IP_8: u2 = 0,
/// unused [8:13]
_unused8: u6 = 0,
/// IP_9 [14:15]
/// Priority of interrupt 9
IP_9: u2 = 0,
/// unused [16:21]
_unused16: u6 = 0,
/// IP_10 [22:23]
/// Priority of interrupt 10
IP_10: u2 = 0,
/// unused [24:29]
_unused24: u6 = 0,
/// IP_11 [30:31]
/// Priority of interrupt 11
IP_11: u2 = 0,
};
/// Use the Interrupt Priority Registers to assign a priority from 0 to 3 to each of the available interrupts. 0 is the highest priority, and 3 is the lowest.
pub const NVIC_IPR2 = Register(NVIC_IPR2_val).init(base_address + 0xe408);

/// NVIC_IPR1
const NVIC_IPR1_val = packed struct {
/// unused [0:5]
_unused0: u6 = 0,
/// IP_4 [6:7]
/// Priority of interrupt 4
IP_4: u2 = 0,
/// unused [8:13]
_unused8: u6 = 0,
/// IP_5 [14:15]
/// Priority of interrupt 5
IP_5: u2 = 0,
/// unused [16:21]
_unused16: u6 = 0,
/// IP_6 [22:23]
/// Priority of interrupt 6
IP_6: u2 = 0,
/// unused [24:29]
_unused24: u6 = 0,
/// IP_7 [30:31]
/// Priority of interrupt 7
IP_7: u2 = 0,
};
/// Use the Interrupt Priority Registers to assign a priority from 0 to 3 to each of the available interrupts. 0 is the highest priority, and 3 is the lowest.
pub const NVIC_IPR1 = Register(NVIC_IPR1_val).init(base_address + 0xe404);

/// NVIC_IPR0
const NVIC_IPR0_val = packed struct {
/// unused [0:5]
_unused0: u6 = 0,
/// IP_0 [6:7]
/// Priority of interrupt 0
IP_0: u2 = 0,
/// unused [8:13]
_unused8: u6 = 0,
/// IP_1 [14:15]
/// Priority of interrupt 1
IP_1: u2 = 0,
/// unused [16:21]
_unused16: u6 = 0,
/// IP_2 [22:23]
/// Priority of interrupt 2
IP_2: u2 = 0,
/// unused [24:29]
_unused24: u6 = 0,
/// IP_3 [30:31]
/// Priority of interrupt 3
IP_3: u2 = 0,
};
/// Use the Interrupt Priority Registers to assign a priority from 0 to 3 to each of the available interrupts. 0 is the highest priority, and 3 is the lowest.\n
pub const NVIC_IPR0 = Register(NVIC_IPR0_val).init(base_address + 0xe400);

/// NVIC_ICPR
const NVIC_ICPR_val = packed struct {
/// CLRPEND [0:31]
/// Interrupt clear-pending bits.\n
CLRPEND: u32 = 0,
};
/// Use the Interrupt Clear-Pending Register to clear pending interrupts and determine which interrupts are currently pending.
pub const NVIC_ICPR = Register(NVIC_ICPR_val).init(base_address + 0xe280);

/// NVIC_ISPR
const NVIC_ISPR_val = packed struct {
/// SETPEND [0:31]
/// Interrupt set-pending bits.\n
SETPEND: u32 = 0,
};
/// The NVIC_ISPR forces interrupts into the pending state, and shows which interrupts are pending.
pub const NVIC_ISPR = Register(NVIC_ISPR_val).init(base_address + 0xe200);

/// NVIC_ICER
const NVIC_ICER_val = packed struct {
/// CLRENA [0:31]
/// Interrupt clear-enable bits.\n
CLRENA: u32 = 0,
};
/// Use the Interrupt Clear-Enable Registers to disable interrupts and determine which interrupts are currently enabled.
pub const NVIC_ICER = Register(NVIC_ICER_val).init(base_address + 0xe180);

/// NVIC_ISER
const NVIC_ISER_val = packed struct {
/// SETENA [0:31]
/// Interrupt set-enable bits.\n
SETENA: u32 = 0,
};
/// Use the Interrupt Set-Enable Register to enable interrupts and determine which interrupts are currently enabled.\n
pub const NVIC_ISER = Register(NVIC_ISER_val).init(base_address + 0xe100);

/// SYST_CALIB
const SYST_CALIB_val = packed struct {
/// TENMS [0:23]
/// An optional Reload value to be used for 10ms (100Hz) timing, subject to system clock skew errors. If the value reads as 0, the calibration value is not known.
TENMS: u24 = 0,
/// unused [24:29]
_unused24: u6 = 0,
/// SKEW [30:30]
/// If reads as 1, the calibration value for 10ms is inexact (due to clock frequency).
SKEW: u1 = 0,
/// NOREF [31:31]
/// If reads as 1, the Reference clock is not provided - the CLKSOURCE bit of the SysTick Control and Status register will be forced to 1 and cannot be cleared to 0.
NOREF: u1 = 0,
};
/// Use the SysTick Calibration Value Register to enable software to scale to any required speed using divide and multiply.
pub const SYST_CALIB = Register(SYST_CALIB_val).init(base_address + 0xe01c);

/// SYST_CVR
const SYST_CVR_val = packed struct {
/// CURRENT [0:23]
/// Reads return the current value of the SysTick counter. This register is write-clear. Writing to it with any value clears the register to 0. Clearing this register also clears the COUNTFLAG bit of the SysTick Control and Status Register.
CURRENT: u24 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// Use the SysTick Current Value Register to find the current value in the register. The reset value of this register is UNKNOWN.
pub const SYST_CVR = Register(SYST_CVR_val).init(base_address + 0xe018);

/// SYST_RVR
const SYST_RVR_val = packed struct {
/// RELOAD [0:23]
/// Value to load into the SysTick Current Value Register when the counter reaches 0.
RELOAD: u24 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// Use the SysTick Reload Value Register to specify the start value to load into the current value register when the counter reaches 0. It can be any value between 0 and 0x00FFFFFF. A start value of 0 is possible, but has no effect because the SysTick interrupt and COUNTFLAG are activated when counting from 1 to 0. The reset value of this register is UNKNOWN.\n
pub const SYST_RVR = Register(SYST_RVR_val).init(base_address + 0xe014);

/// SYST_CSR
const SYST_CSR_val = packed struct {
/// ENABLE [0:0]
/// Enable SysTick counter:\n
ENABLE: u1 = 0,
/// TICKINT [1:1]
/// Enables SysTick exception request:\n
TICKINT: u1 = 0,
/// CLKSOURCE [2:2]
/// SysTick clock source. Always reads as one if SYST_CALIB reports NOREF.\n
CLKSOURCE: u1 = 0,
/// unused [3:15]
_unused3: u5 = 0,
_unused8: u8 = 0,
/// COUNTFLAG [16:16]
/// Returns 1 if timer counted to 0 since last time this was read. Clears on read by application or debugger.
COUNTFLAG: u1 = 0,
/// unused [17:31]
_unused17: u7 = 0,
_unused24: u8 = 0,
};
/// Use the SysTick Control and Status Register to enable the SysTick features.
pub const SYST_CSR = Register(SYST_CSR_val).init(base_address + 0xe010);
};
pub const interrupts = struct {
pub const TIMER_IRQ_3 = 3;
pub const ADC_IRQ_FIFO = 22;
pub const CLOCKS_IRQ = 17;
pub const PIO1_IRQ_0 = 9;
pub const I2C0_IRQ = 23;
pub const XIP_IRQ = 6;
pub const TIMER_IRQ_2 = 2;
pub const UART1_IRQ = 21;
pub const PIO0_IRQ_0 = 7;
pub const DMA_IRQ_1 = 12;
pub const SPI0_IRQ = 18;
pub const IO_IRQ_QSPI = 14;
pub const TIMER_IRQ_0 = 0;
pub const USBCTRL_IRQ = 5;
pub const PIO0_IRQ_1 = 8;
pub const RTC_IRQ = 25;
pub const SIO_IRQ_PROC1 = 16;
pub const UART0_IRQ = 20;
pub const SPI1_IRQ = 19;
pub const PWM_IRQ_WRAP = 4;
pub const TIMER_IRQ_1 = 1;
pub const IO_IRQ_BANK0 = 13;
pub const I2C1_IRQ = 24;
pub const DMA_IRQ_0 = 11;
pub const SIO_IRQ_PROC0 = 15;
pub const PIO1_IRQ_1 = 10;
};
