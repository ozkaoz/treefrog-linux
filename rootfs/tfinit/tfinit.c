/*
 * treefrog-linux diagnostic init — static MIPS32r2 LE
 *
 * Purpose: kernel-only bring-up test. This is the ONLY userspace that runs:
 * no stock OS, no TreeFrogUI, no external rootfs. It proves (1) our kernel
 * boots, (2) which console/output devices work, (3) whether input events flow.
 *
 * Written from scratch for treefrog-linux (GPLv2, same as the kernel it boots).
 * Compiled with the vendor Codescape GCC 6.3.0 mips-mti-linux-gnu toolchain.
 *
 * Strategy:
 *   - print banner to /dev/console (whatever hcboot wired: ttyS0/tty1/virtuart)
 *   - try to open framebuffer(s) and paint a visible test pattern (RGB bars)
 *   - poll /dev/input/js* and /dev/input/event* briefly; report on screen+console
 *   - loop forever blinking so the user SEES it is alive
 */
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/wait.h>

/* local definitions of the stable user-kernel ABI structs we need
 * (identical to include/uapi/linux/{fb.h,input.h} of 4.4) so we don't
 * depend on kernel headers when cross-compiling userspace */
#define TF_FBIOGET_VSCREENINFO 0x4600
#define TF_FBIOGET_FSCREENINFO 0x4602
struct tf_fb_bitfield { unsigned int offset, length, msb_right; };
struct tf_fb_var_screeninfo {
	unsigned int xres, yres, xres_virtual, yres_virtual, xoffset, yoffset;
	unsigned int bits_per_pixel, grayscale;
	struct tf_fb_bitfield red, green, blue, transp;
	unsigned int nonstd, activate, height, width, accel_flags;
	unsigned int pixclock, left_margin, right_margin, upper_margin, lower_margin;
	unsigned int hsync_len, vsync_len, sync, vmode, rotate, colorspace;
};
struct tf_fb_fix_screeninfo {
	char id[16];
	unsigned long smem_start;
	unsigned int smem_len, type, type_aux, visual, xpanstep, ypanstep, ywrapstep, line_length;
	unsigned int mmio_start, mmio_len, accel;
	unsigned short capabilities;
};
struct tf_js_event { unsigned int time; short value; unsigned char type, number; };
struct tf_input_event { struct { long sec, usec; } time; unsigned short type, code; int value; };

static int con = -1;
static int fb_fd = -1;
static unsigned char *fb_mem = 0;
static unsigned int fb_w = 0, fb_h = 0, fb_bpp = 0, fb_stride = 0;
static int fb1_fd = -1;
static unsigned char *fb1_mem = 0;
static unsigned int fb1_w = 0, fb1_h = 0, fb1_stride = 0;

static void log(const char *s)
{
	if (con >= 0) {
		write(con, s, strlen(s));
		write(con, "\r\n", 2);
	}
}
static void logn(const char *s, long v)
{
	char b[64]; int i = 62; int neg = v < 0; unsigned long u = neg ? -v : v;
	b[63] = 0;
	if (!u) b[i--] = '0';
	while (u && i > 0) { b[i--] = '0' + (u % 10); u /= 10; }
	if (neg) b[i--] = '-';
	write(con, s, strlen(s));
	write(con, b + i + 1, 62 - i);
	write(con, "\r\n", 2);
}

static int open_fb(int *fd, unsigned char **mem, unsigned int *w, unsigned int *h,
		   unsigned int *stride, const char *path)
{
	struct tf_fb_var_screeninfo vi;
	struct tf_fb_fix_screeninfo fi;
	*fd = open(path, O_RDWR);
	if (*fd < 0) return -1;
	if (ioctl(*fd, TF_FBIOGET_VSCREENINFO, &vi) < 0) return -2;
	if (ioctl(*fd, TF_FBIOGET_FSCREENINFO, &fi) < 0) return -3;
	*w = vi.xres; *h = vi.yres; *stride = fi.line_length;
	*mem = mmap(0, fi.smem_len, PROT_WRITE, MAP_SHARED, *fd, 0);
	if (*mem == MAP_FAILED) { *mem = 0; return -4; }
	return 0;
}

static void paint_bars(unsigned char *mem, unsigned int w, unsigned int h,
		       unsigned int stride, int bpp, int phase)
{
	unsigned int x, y;
	for (y = 0; y < h; y++) {
		for (x = 0; x < w; x++) {
			unsigned char *p = mem + y * stride + (x * bpp) / 8;
			int band = (x * 8) / w;
			unsigned char r = 0, g = 0, b = 0;
			switch (band) {
			case 0: r = 255; break;
			case 1: g = 255; break;
			case 2: b = 255; break;
			case 3: r = g = 255; break;
			case 4: g = b = 255; break;
			case 5: r = b = 255; break;
			case 6: r = g = b = 60; break;
			default: r = g = b = (phase ? 255 : 0); break;
			}
			if (bpp == 16) {
				unsigned short px = ((r & 0xf8) << 8) | ((g & 0xfc) << 3) | (b >> 3);
				*(unsigned short *)p = px;
			} else {
				p[0] = b; p[1] = g; p[2] = r;
				if (bpp == 32) p[3] = 255;
			}
		}
	}
}

static void probe_input(void)
{
	static const char *js[] = { "/dev/input/js0", "/dev/input/js1", "/dev/input/js2", "/dev/input/js3" };
	int i;
	for (i = 0; i < 4; i++) {
		int fd = open(js[i], O_RDONLY | O_NONBLOCK);
		if (fd >= 0) {
			log("[tf] FOUND "); log(js[i]);
			/* drain briefly: any event during 400ms proves input pipeline */
			int n; struct tf_js_event { unsigned int t; short v; unsigned char t2, n2; } ev;
			int got = 0;
			for (;;) {
				n = read(fd, &ev, sizeof(ev));
				if (n == sizeof(ev)) got++;
				else break;
			}
			if (got) { log("[tf] -> EVENTS FLOWING (n="); logn("", got); log(")"); }
			else log("[tf] -> open ok, no events yet");
			close(fd);
		}
	}
	fd_event:
	{
		int fd = open("/dev/input/event0", O_RDONLY | O_NONBLOCK);
		if (fd >= 0) { log("[tf] FOUND /dev/input/event0"); close(fd); }
	}
}

int main(void)
{
	int phase = 0;
	int iteration = 0;

	con = open("/dev/console", O_WRONLY);
	if (con < 0) con = open("/dev/ttyS0", O_WRONLY | O_NOCTTY);

	log("[tf] === treefrog-linux kernel-only bring-up ===");
	log("[tf] our kernel is ALIVE. no stock OS, no TreeFrogUI.");

	/* framebuffers: stock DTB provides fb0 (720x1280) and fb1 (640x480 OSD) */
	{
		int r = open_fb(&fb_fd, &fb_mem, &fb_w, &fb_h, &fb_stride, "/dev/fb0");
		if (r == 0 && fb_mem) {
			log("[tf] fb0 OK ");
			logn("w=", fb_w); logn("h=", fb_h); logn("stride=", fb_stride);
		} else { log("[tf] fb0 FAIL ("); logn("", r); log(")"); }
	}
	{
		int r = open_fb(&fb1_fd, &fb1_mem, &fb1_w, &fb1_h, &fb1_stride, "/dev/fb1");
		if (r == 0 && fb1_mem) {
			log("[tf] fb1 OK ");
			logn("w=", fb1_w); logn("h=", fb1_h); logn("stride=", fb1_stride);
		} else { log("[tf] fb1 FAIL ("); logn("", r); log(")"); }
	}

	probe_input();

	/* visible proof loop: bars + blinking band; also heartbeat to console */
	log("[tf] painting test pattern... if you see COLOR BARS, kernel+fb work.");
	for (;;) {
		if (fb_mem)  paint_bars(fb_mem,  fb_w,  fb_h,  fb_stride,  32, phase);
		if (fb1_mem) paint_bars(fb1_mem, fb1_w, fb1_h, fb1_stride, 16, phase);
		phase = !phase;
		if ((iteration++ & 7) == 0) { log("[tf] alive #"); logn("", iteration >> 3); }
		probe_input();
		sleep(1);
	}
	return 0;
}
