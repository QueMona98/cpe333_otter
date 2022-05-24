# This program will fill the screen with a BG_COLOR before
# drawing 3 dots, a horizontal, and vertical lines
#
# coordinates are given in row major format
# (col,row) = (x,y)
# written by J. Calllenes and P. Hummel

.eqv BG_COLOR, 0x0F	 # light blue (0/7 red, 3/7 green, 3/3 blue)
.eqv VG_ADDR, 0x11000120
.eqv VG_COLOR, 0x11000140
.eqv VG_READ, 0x11000160
.eqv MMIO,0x11000000 

.data 
SCANCODE: 
	
#array: 	# test codes for EXTERNAL ADDER TESTS
#	.half 0x1d,0x1d,0x1d,0x1d,0x1d,0x1d,0x1d,0x1d,0x1d,0x1d,0x1d,0x1d,0x1d
.text

init:
        li sp, 0x10000     #initialize stack pointer
	li s2, VG_ADDR     #load MMIO addresses 
	li s3, VG_COLOR
	li s11, VG_READ	   #  READ from Buffer
	
	li   s0, MMIO        # pointer for MMIO
      	la   s1, SCANCODE    # pointer to scancode
      	
      	li s5, 28	     # A keystroke
      	li s6, 29	     # W keystroke
      	li s7, 27	     # S keystroke
      	li s8, 35	     # D keystroke
      	
      	li s9, 0xE0          # red
      	li s10, 0x1C	     # green
      	
#      	la s11, array		# load in test codes
    
      	la t3, ISR         # register the interrupt handler
      	csrrw x0, mtvec, t3
      	li    t3, 1           # enable interrupts
      	csrrw x0, mie, t3

      	add   t3, x0, x0      # initialize  flag
      	add   s4, x0, x0      # initialize interrupt count
      	sw    s4, 0x40(s0)    # clear 7Seg
      	sw    s4, 0x20(s0)    # clear LEDs
      

	# fill screen using default color
	call 	draw_background  # must not modify s2, s3
	add t4, x0, x0		# t4 to zero again
	j DrawCourse
	
startgame:   
	j game
	
DrawCourse:
	li a0, 57		# X coordinate
	li a1, 2		# Y coordinate
	li a3, 0x1C		# color green (7/7 red, 0/7 green, 0/3 blue)
	call draw_dot  # must not modify s2, s3

	li a0, 56		# X coordinate
	li a1, 2		# Y coordinate
	li a3, 0x1C		# color green (7/7 red, 0/7 green, 0/3 blue)
	call draw_dot  # must not modify s2, s3
	
	li a0, 57		# X coordinate
	li a1, 3		# Y coordinate
	li a3, 0x1C		# color green (7/7 red, 0/7 green, 0/3 blue)
	call draw_dot  # must not modify s2, s3

	li a0, 56		# X coordinate
	li a1, 3		# Y coordinate
	li a3, 0x1C		# color green (7/7 red, 0/7 green, 0/3 blue)
	call draw_dot  # must not modify s2, s3

	# top screen border
	li a3, 0xE0		# color red (7/7 red, 0/7 green, 0/3 blue)
	li a0, 0		# start X coordinate
	li a1, 0		# Y coordinate
	li a2, 79		# ending X coordinate
	call draw_horizontal_line  # must not modify: a3, s2, s3
	# low screen border
	li a3, 0xE0		# color red (7/7 red, 0/7 green, 0/3 blue)
	li a0, 0		# start X coordinate
	li a1, 59		# Y coordinate
	li a2, 79		# ending X coordinate
	call draw_horizontal_line  # must not modify: a3, s2, s3
	# left side border
	li a0, 0		# X coordinate
	li a1, 1		# starting Y coordinate
	li a2, 59		# ending Y coordinate
	call draw_vertical_line  # must not modify s2, s3
	# right side border
	li a0, 79		# X coordinate
	li a1, 0		# starting Y coordinate
	li a2, 59		# ending Y coordinate
	call draw_vertical_line  # must not modify s2, s3
	
	# player block
	li a0, 48		# X coordinate
	li a1, 58		# Y coordinate
	li a3, 0xFF		# color red (7/7 red, 0/7 green, 0/3 blue)
	call draw_dot  # must not modify s2, s3
	
	
	# BLOCK 1
	li a3, 0xE0		# color red (7/7 red, 0/7 green, 0/3 blue)
	li a0, 35		# start X coordinate
	li a1, 54		# Y coordinate
	li a2, 47		# ending X coordinate
	call draw_horizontal_line
	
	li a3, 0xE0		# color red (7/7 red, 0/7 green, 0/3 blue)
	li a0, 35		# start X coordinate
	li a1, 55		# Y coordinate
	li a2, 47		# ending X coordinate
	call draw_horizontal_line
	
	li a3, 0xE0		# color red (7/7 red, 0/7 green, 0/3 blue)
	li a0, 35		# start X coordinate
	li a1, 56		# Y coordinate
	li a2, 47		# ending X coordinate
	call draw_horizontal_line
	
	li a3, 0xE0		# color red (7/7 red, 0/7 green, 0/3 blue)
	li a0, 35		# start X coordinate
	li a1, 57		# Y coordinate
	li a2, 47		# ending X coordinate
	call draw_horizontal_line
	
	li a3, 0xE0		# color red (7/7 red, 0/7 green, 0/3 blue)
	li a0, 35		# start X coordinate
	li a1, 58		# Y coordinate
	li a2, 47		# ending X coordinate
	call draw_horizontal_line
	
	li a3, 0xE0		# color red (7/7 red, 0/7 green, 0/3 blue)
	li a0, 35		# start X coordinate
	li a1, 59		# Y coordinate
	li a2, 47		# ending X coordinate
	call draw_horizontal_line
	
	# BLOCK 2
	li a3, 0xE0		# color red (7/7 red, 0/7 green, 0/3 blue)
	li a0, 49		# start X coordinate
	li a1, 54		# Y coordinate
	li a2, 65		# ending X coordinate
	call draw_horizontal_line
	
	li a3, 0xE0		# color red (7/7 red, 0/7 green, 0/3 blue)
	li a0, 49		# start X coordinate
	li a1, 55		# Y coordinate
	li a2, 65		# ending X coordinate
	call draw_horizontal_line
	
	li a3, 0xE0		# color red (7/7 red, 0/7 green, 0/3 blue)
	li a0, 49		# start X coordinate
	li a1, 56		# Y coordinate
	li a2, 65		# ending X coordinate
	call draw_horizontal_line
	
	li a3, 0xE0		# color red (7/7 red, 0/7 green, 0/3 blue)
	li a0, 49		# start X coordinate
	li a1, 57		# Y coordinate
	li a2, 65		# ending X coordinate
	call draw_horizontal_line
	
	li a3, 0xE0		# color red (7/7 red, 0/7 green, 0/3 blue)
	li a0, 49		# start X coordinate
	li a1, 58		# Y coordinate
	li a2, 65		# ending X coordinate
	call draw_horizontal_line
	
	li a3, 0xE0		# color red (7/7 red, 0/7 green, 0/3 blue)
	li a0, 49		# start X coordinate
	li a1, 59		# Y coordinate
	li a2, 65		# ending X coordinate
	call draw_horizontal_line
	
	# BLOCK 3
	li a3, 0xE0		# color red (7/7 red, 0/7 green, 0/3 blue)
	li a0, 49		# start X coordinate
	li a1, 50		# Y coordinate
	li a2, 65		# ending X coordinate
	call draw_horizontal_line
	
	li a3, 0xE0		# color red (7/7 red, 0/7 green, 0/3 blue)
	li a0, 49		# start X coordinate
	li a1, 51		# Y coordinate
	li a2, 65		# ending X coordinate
	call draw_horizontal_line
	
	li a3, 0xE0		# color red (7/7 red, 0/7 green, 0/3 blue)
	li a0, 49		# start X coordinate
	li a1, 52		# Y coordinate
	li a2, 65		# ending X coordinate
	call draw_horizontal_line
	
	li a3, 0xE0		# color red (7/7 red, 0/7 green, 0/3 blue)
	li a0, 49		# start X coordinate
	li a1, 53		# Y coordinate
	li a2, 65		# ending X coordinate
	call draw_horizontal_line
	
	# BLOCK 4
	li a3, 0xE0		# color red (7/7 red, 0/7 green, 0/3 blue)
	li a0, 49		# start X coordinate
	li a1, 20		# Y coordinate
	li a2, 65		# ending X coordinate
	call draw_horizontal_line
	
	li a3, 0xE0		# color red (7/7 red, 0/7 green, 0/3 blue)
	li a0, 49		# start X coordinate
	li a1, 21		# Y coordinate
	li a2, 65		# ending X coordinate
	call draw_horizontal_line
	
	li a3, 0xE0		# color red (7/7 red, 0/7 green, 0/3 blue)
	li a0, 49		# start X coordinate
	li a1, 22		# Y coordinate
	li a2, 65		# ending X coordinate
	call draw_horizontal_line
	
	li a3, 0xE0		# color red (7/7 red, 0/7 green, 0/3 blue)
	li a0, 49		# start X coordinate
	li a1, 23		# Y coordinate
	li a2, 65		# ending X coordinate
	call draw_horizontal_line
	
	li a3, 0xE0		# color red (7/7 red, 0/7 green, 0/3 blue)
	li a0, 49		# start X coordinate
	li a1, 24		# Y coordinate
	li a2, 65		# ending X coordinate
	call draw_horizontal_line	
	
	# BLOCK 5
	li a0, 68		        # X coordinate
	li a1, 45		# starting Y coordinate
	li a2, 53	# ending Y coordinate
	call draw_vertical_line  # must not modify s2, s3
	
	li a0, 67		        # X coordinate
	li a1, 45		# starting Y coordinate
	li a2, 53	# ending Y coordinate
	call draw_vertical_line  # must not modify s2, s3
	
	li a0, 68		        # X coordinate
	li a1, 45		# starting Y coordinate
	li a2, 53	# ending Y coordinate
	call draw_vertical_line  # must not modify s2, s3
	
	li a0, 69		        # X coordinate
	li a1, 45		# starting Y coordinate
	li a2, 53	# ending Y coordinate
	call draw_vertical_line  # must not modify s2, s3
	
	li a0, 70		        # X coordinate
	li a1, 45		# starting Y coordinate
	li a2, 53	# ending Y coordinate
	call draw_vertical_line  # must not modify s2, s3
	
	# BLOCK 6
	li a3, 0xE0		# color red (7/7 red, 0/7 green, 0/3 blue)
	li a0, 68		# start X coordinate
	li a1, 57		# Y coordinate
	li a2, 79		# ending X coordinate
	call draw_horizontal_line  # must not modify: a3, s2, s3
	
	li a3, 0xE0		# color red (7/7 red, 0/7 green, 0/3 blue)
	li a0, 68		# start X coordinate
	li a1, 58		# Y coordinate
	li a2, 79		# ending X coordinate
	call draw_horizontal_line  # must not modify: a3, s2, s3
	
	li a3, 0xE0		# color red (7/7 red, 0/7 green, 0/3 blue)
	li a0, 68		# start X coordinate
	li a1, 58		# Y coordinate
	li a2, 79		# ending X coordinate
	call draw_horizontal_line  # must not modify: a3, s2, s3
	
	# BLOCK 7
	li a3, 0xE0		# color red (7/7 red, 0/7 green, 0/3 blue)
	li a0, 30		# start X coordinate
	li a1, 25		# Y coordinate
	li a2, 79		# ending X coordinate
	call draw_horizontal_line  # must not modify: a3, s2, s3
	
	li a3, 0xE0		# color red (7/7 red, 0/7 green, 0/3 blue)
	li a0, 30		# start X coordinate
	li a1, 26		# Y coordinate
	li a2, 79		# ending X coordinate
	call draw_horizontal_line  # must not modify: a3, s2, s3
	
	li a3, 0xE0		# color red (7/7 red, 0/7 green, 0/3 blue)
	li a0, 30		# start X coordinate
	li a1, 27		# Y coordinate
	li a2, 79		# ending X coordinate
	call draw_horizontal_line  # must not modify: a3, s2, s3
	
	# BLOCK 8
	li a0, 20		        # X coordinate
	li a1, 41		# starting Y coordinate
	li a2, 50		# ending Y coordinate
	call draw_vertical_line  # must not modify s2, s3
	
	li a0, 21			        # X coordinate
	li a1, 41		# starting Y coordinate
	li a2, 50		# ending Y coordinate
	call draw_vertical_line  # must not modify s2, s3
	
	# BLOCK 9
	li a3, 0xE0		# color red (7/7 red, 0/7 green, 0/3 blue)
	li a0, 5		# start X coordinate
	li a1, 5		# Y coordinate
	li a2, 20		# ending X coordinate
	call draw_horizontal_line  # must not modify: a3, s2, s3
	
	li a3, 0xE0		# color red (7/7 red, 0/7 green, 0/3 blue)
	li a0, 35		# start X coordinate
	li a1, 52		# Y coordinate
	li a2, 50		# ending X coordinate
	call draw_horizontal_line  # must not modify: a3, s2, s3
	
	# BLOCK 10
	li a0, 32		        # X coordinate
	li a1, 40		# starting Y coordinate
	li a2, 59		# ending Y coordinate
	call draw_vertical_line  # must not modify s2, s3
	
	li a0, 33		        # X coordinate
	li a1, 40		# starting Y coordinate
	li a2, 59		# ending Y coordinate
	call draw_vertical_line  # must not modify s2, s3
	
	
	# BLOCK 11
	li a0, 10		        # X coordinate
	li a1, 15		# starting Y coordinate
	li a2, 50		# ending Y coordinate
	call draw_vertical_line  # must not modify s2, s3
	
	li a0, 11		        # X coordinate
	li a1, 15		# starting Y coordinate
	li a2, 50		# ending Y coordinate
	call draw_vertical_line  # must not modify s2, s3
	
	li a0, 12		        # X coordinate
	li a1, 15		# starting Y coordinate
	li a2, 50		# ending Y coordinate
	call draw_vertical_line  # must not modify s2, s3
	
	li a0, 13		        # X coordinate
	li a1, 15		# starting Y coordinate
	li a2, 50		# ending Y coordinate
	call draw_vertical_line  # must not modify s2, s3
	
	li a0, 14		        # X coordinate
	li a1, 15		# starting Y coordinate
	li a2, 50		# ending Y coordinate
	call draw_vertical_line  # must not modify s2, s3
	
	li a0, 15		        # X coordinate
	li a1, 15		# starting Y coordinate
	li a2, 50		# ending Y coordinate
	call draw_vertical_line  # must not modify s2, s3
	
	# BLOCK 12
	li a0, 20		        # X coordinate
	li a1, 9		# starting Y coordinate
	li a2, 50		# ending Y coordinate
	call draw_vertical_line  # must not modify s2, s3
	
	li a0, 21		        # X coordinate
	li a1, 9		# starting Y coordinate
	li a2, 50		# ending Y coordinate
	call draw_vertical_line  # must not modify s2, s3
	
	li a0, 22		        # X coordinate
	li a1, 9		# starting Y coordinate
	li a2, 50		# ending Y coordinate
	call draw_vertical_line  # must not modify s2, s3
	
	# BLOCK 15
	li a3, 0xE0		# color red (7/7 red, 0/7 green, 0/3 blue)
	li a0, 10		# start X coordinate
	li a1, 5		# Y coordinate
	li a2, 54		# ending X coordinate
	call draw_horizontal_line  # must not modify: a3, s2, s3
	
	li a3, 0xE0		# color red (7/7 red, 0/7 green, 0/3 blue)
	li a0, 10		# start X coordinate
	li a1, 6		# Y coordinate
	li a2, 54		# ending X coordinate
	call draw_horizontal_line  # must not modify: a3, s2, s3
	
	li a3, 0xE0		# color red (7/7 red, 0/7 green, 0/3 blue)
	li a0, 10		# start X coordinate
	li a1, 7		# Y coordinate
	li a2, 54		# ending X coordinate
	call draw_horizontal_line  # must not modify: a3, s2, s3
	
	li a3, 0xE0		# color red (7/7 red, 0/7 green, 0/3 blue)
	li a0, 10		# start X coordinate
	li a1, 8		# Y coordinate
	li a2, 54		# ending X coordinate
	call draw_horizontal_line  # must not modify: a3, s2, s3
	
	# BLOCK 19
	li a3, 0xE0		# color red (7/7 red, 0/7 green, 0/3 blue)
	li a0, 58		# start X coordinate
	li a1, 7		# Y coordinate
	li a2, 79		# ending X coordinate
	call draw_horizontal_line  # must not modify: a3, s2, s3
	
	li a3, 0xE0		# color red (7/7 red, 0/7 green, 0/3 blue)
	li a0, 58		# start X coordinate
	li a1, 8		# Y coordinate
	li a2, 79		# ending X coordinate
	call draw_horizontal_line  # must not modify: a3, s2, s3
	
	li a3, 0xE0		# color red (7/7 red, 0/7 green, 0/3 blue)
	li a0, 58		# start X coordinate
	li a1, 9		# Y coordinate
	li a2, 79		# ending X coordinate
	call draw_horizontal_line  # must not modify: a3, s2, s3
	
	li a3, 0xE0		# color red (7/7 red, 0/7 green, 0/3 blue)
	li a0, 58		# start X coordinate
	li a1, 10		# Y coordinate
	li a2, 79		# ending X coordinate
	call draw_horizontal_line  # must not modify: a3, s2, s3
	
	# BLOCK 20
	li a3, 0xE0		# color red (7/7 red, 0/7 green, 0/3 blue)
	li a0, 30		# start X coordinate
	li a1, 43		# Y coordinate
	li a2, 68		# ending X coordinate
	call draw_horizontal_line  # must not modify: a3, s2, s3
	
	li a3, 0xE0		# color red (7/7 red, 0/7 green, 0/3 blue)
	li a0, 30		# start X coordinate
	li a1, 44		# Y coordinate
	li a2, 68		# ending X coordinate
	call draw_horizontal_line  # must not modify: a3, s2, s3
	
	li a3, 0xE0		# color red (7/7 red, 0/7 green, 0/3 blue)
	li a0, 30		# start X coordinate
	li a1, 45		# Y coordinate
	li a2, 68		# ending X coordinate
	call draw_horizontal_line  # must not modify: a3, s2, s3
	
	# BLOCK 21
	li a0, 35		        # X coordinate
	li a1, 30		# starting Y coordinate
	li a2, 40		# ending Y coordinate
	call draw_vertical_line  # must not modify s2, s3
	
	li a0, 36		        # X coordinate
	li a1, 30		# starting Y coordinate
	li a2, 42		# ending Y coordinate
	call draw_vertical_line  # must not modify s2, s3
	
	li a0, 37		        # X coordinate
	li a1, 40		# starting Y coordinate
	li a2, 43		# ending Y coordinate
	call draw_vertical_line  # must not modify s2, s3
	
	# BLOCK 22
	li a0, 55		        # X coordinate
	li a1, 5		# starting Y coordinate
	li a2, 8		# ending Y coordinate
	call draw_vertical_line  # must not modify s2, s3
	
	li a0, 56		        # X coordinate
	li a1, 5		# starting Y coordinate
	li a2, 8		# ending Y coordinate
	call draw_vertical_line  # must not modify s2, s3
	
	li a0, 57		        # X coordinate
	li a1, 5		# starting Y coordinate
	li a2, 8		# ending Y coordinate
	call draw_vertical_line  # must not modify s2, s3
	
	# BLOCK 23
	li a3, 0xE0		# color red (7/7 red, 0/7 green, 0/3 blue)
	li a0, 1		# start X coordinate
	li a1, 15		# Y coordinate
	li a2, 9		# ending X coordinate
	call draw_horizontal_line
	
	li a3, 0xE0		# color red (7/7 red, 0/7 green, 0/3 blue)
	li a0, 1		# start X coordinate
	li a1, 16		# Y coordinate
	li a2, 9		# ending X coordinate
	call draw_horizontal_line
	li a3, 0xE0		# color red (7/7 red, 0/7 green, 0/3 blue)
	li a0, 1		# start X coordinate
	li a1, 17		# Y coordinate
	li a2, 9		# ending X coordinate
	call draw_horizontal_line
	
	# BLOCK 24
	li a0, 13	        # X coordinate
	li a1, 55		# starting Y coordinate
	li a2, 57		# ending Y coordinate
	call draw_vertical_line  # must not modify s2, s3
	
	li a0, 14		        # X coordinate
	li a1, 55		# starting Y coordinate
	li a2, 57		# ending Y coordinate
	call draw_vertical_line  # must not modify s2, s3
	
	li a0, 15		        # X coordinate
	li a1, 55		# starting Y coordinate
	li a2, 57		# ending Y coordinate
	call draw_vertical_line  # must not modify s2, s3

	j startgame # continuous loop

# draws a horizontal line from (a0,a1) to (a2,a1) using color in a3
# Modifies (directly or indirectly): t0, t1, a0, a2
draw_horizontal_line:
	addi sp,sp,-4
	sw ra, 0(sp)
	addi a2,a2,1	#go from a0 to a2 inclusive
draw_horiz1:
	call draw_dot  # must not modify: a0, a1, a2, a3
	addi a0,a0,1
	bne a0,a2, draw_horiz1
	lw ra, 0(sp)
	addi sp,sp,4
	ret

# draws a vertical line from (a0,a1) to (a0,a2) using color in a3
# Modifies (directly or indirectly): t0, t1, a1, a2
draw_vertical_line:
	addi sp,sp,-4
	sw ra, 0(sp)
	addi a2,a2,1
draw_vert1:
	call draw_dot  # must not modify: a0, a1, a2, a3
	addi a1,a1,1
	bne a1,a2,draw_vert1
	lw ra, 0(sp)
	addi sp,sp,4
	ret

# Fills the 60x80 grid with one color using successive calls to draw_horizontal_line
# Modifies (directly or indirectly): t0, t1, t4, a0, a1, a2, a3
draw_background:
	addi sp,sp,-4
	sw ra, 0(sp)
	li a3, BG_COLOR	#use default color
	li a1, 0	#a1= row_counter
	li t4, 60 	#max rows
start0:	li a0, 0
	li a2, 79 	#total number of columns
	call draw_horizontal_line  # must not modify: t4, a1, a3
	addi a1,a1, 1
	bne t4,a1, start0	#branch to draw more rows
	lw ra, 0(sp)
	addi sp,sp,4
	ret
# fills 60 x 80 gride with solid green color for successfully finding end gate	
draw_endground:
	addi sp,sp,-4
	sw ra, 0(sp)
	add a3, x0, s10 # color green for end game
	li a1, 0	#a1= row_counter
	li t4, 60 	#max rows
start1:	li a0, 0
	li a2, 79 	#total number of columns
	call draw_horizontal_line  # must not modify: t4, a1, a3
	addi a1,a1, 1
	bne t4,a1, start1	#branch to draw more rows
	lw ra, 0(sp)
	addi sp,sp,4
	ret

# draws a dot on the display at the given coordinates:
# 	(X,Y) = (a0,a1) with a color stored in a3
# 	(col, row) = (a0,a1)
# Modifies (directly or indirectly): t0, t1
draw_dot:
	andi t0,a0,0x7F	# select bottom 7 bits (col)
	andi t1,a1,0x3F	# select bottom 6 bits  (row)
	slli t1,t1,7	#  {a1[5:0],a0[6:0]} 
	or t0,t1,t0	# 13-bit address
	sw t0, 0(s2)	# write 13 address bits to register
	sw a3, 0(s3)	# write color data to frame buffer	
	ret
	
read_dot:
	andi t0,a0,0x7F	# select bottom 7 bits (col)
	andi t1,a1,0x3F	# select bottom 6 bits  (row)
	slli t1,t1,7	#  {a1[5:0],a0[6:0]} 
	or t0,t1,t0	# 13-bit address
	sw t0, 0(s2)    # write 13 bits to register
	lw t0, 0(s11)	# load RD router from wrapper 
	#lw a3, 0(s3)	# color color data from vga display; ***recently added***
	ret	
	
game: addi a0, x0, 48	# set location of player block
      addi a1, x0, 58
      addi a3, x0, 0xFF # set player block color
       
loop: beq   t3, x0, loop    # check for interrupt flag
      lw    t4, 0(s1)       # read saved scancode
      sw    t4, 0x40(s0)    # set 7Seg
      addi  s4, s4,  1      # increment interrupt count
      sw    s4, 0x20(s0)    # output to LEDS
      # use one of 4 possible key strokes to write dot in location and color prevouse dot as background
      bne x0, t3, BOUND	    # if keystroke dected check for boundary   
noact:      
      csrrw x0, mie, t3     # re-enable interrupts
      addi  t3, x0, 0       # clear interrupt flag
      j     loop
      
 end: jal ra, draw_endground
      j end
 

ISR:  lw   t3, 0x100(s0)  # read scancode 
      sw   t3, 0(s1)      # save to SCANCODE
      addi t3, x0, 1      # set interrupt flag
      mret
      
BOUND: beq t4, s5, Astroke
       beq t4, s6, Wstroke
       beq t4, s7, Sstroke
       beq t4, s8, Dstroke
       j noact

Astroke:			# move player left
	addi a0, a0, -1		# increment in direction
	jal ra, read_dot 	# check for red or green block
	addi a0, a0, 1		# return to original value
	beq t0, s9, noact	# if red return to loop
	beq t0, s10, end	# if green go to end and trap
	
	li a3, BG_COLOR	#use default color
	jal ra, draw_dot
	addi a3, x0, 0xFF # set player block color
	addi a0, a0, -1	# col
	jal ra, draw_dot
	j noact
Wstroke:		# move up
	addi a1, a1, -1	# row
	jal ra, read_dot # check for red or green block
	addi a1, a1, 1	# return to original value
	beq t0, s9, noact	# if red return to loop
	beq t0, s10, end	# if green go to end and trap
	
	li a3, BG_COLOR	#use default color
	jal ra, draw_dot
	addi a3, x0, 0xFF # set player block color
	addi a1, a1, -1	# row
	jal ra, draw_dot
	j noact
	
Sstroke:		# move down
	addi a1, a1, 1	# row
	jal ra, read_dot # check for red or green block
	addi a1, a1, -1	# return to original value
	beq t0, s9, noact	# if red return to loop
	beq t0, s10, end	# if green go to end and trap
	
	li a3, BG_COLOR	#use default color
	jal ra, draw_dot
	addi a3, x0, 0xFF # set player block color
	addi a1, a1, 1	# row
	jal ra, draw_dot
	j noact
Dstroke:		# move right
	addi a0, a0, 1	# row
	jal ra, read_dot # check for red or green block
	addi a0, a0, -1	# return to original value
	beq t0, s9, noact	# if red return to loop
	beq t0, s10, end	# if green go to end and trap

	li a3, BG_COLOR	#use default color
	jal ra, draw_dot
	addi a3, x0, 0xFF # set player block color
	addi a0, a0, 1	# col
	jal ra, draw_dot
	j noact
