`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Joseph Callenes
//           
// 
// Create Date: 02/06/2020 06:40:37 PM
// Design Name: 
// Module Name: dcache
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - 
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
package cache_def;
 
parameter int TAG_MSB = 31;
parameter int TAG_LSB = 12;
 
typedef struct packed{
	logic valid;
	logic dirty;
	logic [TAG_MSB:TAG_LSB] tag;
    }cache_tag_type;
 
typedef struct {
	logic [9:0] index;
	logic we;
    }cache_req_type;
 
//128-bit cache line
typedef logic [127:0] cache_data_type;
 
//CPU request (CPU ->cache controller)
typedef struct{
	logic [31:0] addr;
	logic [31:0] data;
	logic rw;
	logic valid;
    }cpu_req_type;
 
//Cache result (cache controller -> CPU)
typedef struct {
	logic [31:0]data;
	logic ready;
    }cpu_result_type;
 
//memory request (cache controller -> memory)
typedef struct {
	logic [31:0]addr;
	logic [127:0]data;
	logic rw;
	logic valid;
    }mem_req_type;
 
//memory controller response (memory -> cache controller)
typedef struct {
    cache_data_type data;
    logic ready;
    }mem_data_type;
endpackage
 
import cache_def::*;
import memory_bus_sizes::*;
 
module L1_cache_data (
	input clk,
	input cache_req_type data_req,
	input cache_data_type data_write,
	input [3:0] be,
	input [1:0] block_offset,
	input from_ram,
	output cache_data_type data_read);
	
	cache_data_type data_mem[0:255];
	
	initial 
	begin
    	for(int i=0; i<256; i++)
        	data_mem[i]='0;
	end
 
always_ff @(posedge clk) 
	begin
    	if(data_req.we) 
    	begin
        	if(from_ram)
            	data_mem[data_req.index] <= data_write;
        	if(!from_ram) 
        	begin
          	for (int b = 0; b < WORD_SIZE; b++) 
          	begin
            	if (be[b]) 
            	begin
                    data_mem[data_req.index][block_offset*WORD_WIDTH+b*8+:8] = data_write[block_offset*WORD_WIDTH+b*8+:8];  //[b*8+:8];
            	end
       	   end
           end
    	end
	end
	assign data_read = data_mem[data_req.index];
endmodule
 
module L1_cache_tag ( //includes syncronou writes and async reads
	input logic clk,
	input cache_req_type tag_req,
	input cache_tag_type tag_write,
	output cache_tag_type tag_read);
	
 	cache_tag_type tag_mem[0:255];
    always_ff @(posedge clk) 
    begin
    	if(tag_req.we) 
    	begin
        	tag_mem[tag_req.index] <= tag_write;
    	end
	end
	assign tag_read = tag_mem[tag_req.index]; 
endmodule

module dcache(
	input clk, RESET,
	axi_bus_rw.device cpu,
	axi_bus_rw.controller mem
	);
 
	cpu_req_type cpu_req; 	//CPU->cache
	mem_data_type mem_data;   //memory->cache
	
	mem_req_type mem_req;	//cache->memory
	cpu_result_type cpu_res;  //cache->CPU
	
	logic [1:0] block_offset;
	logic [3:0] be;
	logic from_ram;
	logic wait_read, next_wait_read;  
	logic [9:0] i;
	logic [8:0] strobe;
	logic [128:0] bitmask;
	logic hit;
	assign hit = cpu.read_addr_valid ? cpu.read_addr[31:12] == tag_read.tag && tag_read.valid : cpu.write_addr[31:12] == tag_read.tag && tag_read.valid;
	
	typedef enum {compare_tag, allocate, writeback, save} cache_state_type;
  
	cache_state_type state, next_state;
 
	cache_tag_type tag_read;
	cache_tag_type tag_write;
	cache_req_type tag_req;
	
	cache_data_type data_read;
	cache_data_type data_write;
	cache_req_type data_req;
	
	cpu_result_type next_cpu_res;
 
always_ff @(posedge clk) 
begin
    if (RESET == 1) 
    begin
        state = compare_tag;
   	end
   	else
        state = next_state;
    end
           	
	always_comb 
	begin
        case (state)
//COMPARE TAG        
        compare_tag: 
        begin
            cpu.read_addr_ready <= 1;
        	cpu.write_addr_ready <= 1;
        	cpu.read_data_valid <= 0;
        	cpu.write_resp_valid <=0;
       	   	
       	   	tag_req.we <= 0;
       	   	data_req.we <= 0;
       	   	
       	   	tag_req.index <= cpu.write_addr_valid ? cpu.write_addr[11:4] : cpu.read_addr[11:4];
       	   	data_req.index <= cpu.write_addr_valid ? cpu.write_addr[11:4] : cpu.read_addr[11:4];
       	   	
       	   	next_state <= compare_tag;
       	   	//check if hit occurs
       	   	if (hit) 
       	   	begin
        	   if (cpu.read_addr_valid) 
        	   begin
        	       	strobe = 32 * cpu.read_addr[3:2];
                   	cpu.read_data <= data_read >> (strobe);
       	           	cpu.read_data_valid <= 1;
        	   end
       	       	else if (cpu.write_addr_valid) 
       	       	begin
       	           	data_req.we <= 1;
       	           	block_offset = cpu.write_addr[1:0];
     	     	    from_ram = 0;
        	        strobe = 32 * cpu.write_addr[3:2];
        	       	bitmask = (32'hffffffff << strobe);
        	       	be <= cpu.strobe;
       	           	data_write <= ((mem.read_data & ~bitmask) | (cpu.write_data << strobe));
                   	tag_req.we <= 1;
       	           	tag_write.dirty <= 1;
       	           	cpu.write_resp_valid<= 1;
       	       	end
        	   	end
        	   	else if(cpu.read_addr_valid || cpu.write_addr_valid)
        	   	begin
        	       	if (tag_read.dirty) 
        	       	begin
        	           	next_state <= writeback;
        	           	mem.write_data <= data_read;
        	       	end
        	       	else
        	           	next_state <= allocate;
        	   	end
        	    end
//WRITEBACK        
        writeback: 
        	begin
          	   mem.read_addr_valid <= 0;
       	   	   mem.write_addr_valid <= 1;
       	   	   cpu.read_addr_ready <= 0;
       	   	   cpu.write_addr_ready <= 0;
       	   	   cpu.read_data_valid <= 0;
        	   if (cpu.read_addr_valid)
        	      mem.write_addr <= {tag_read.tag, cpu.read_addr[11:0]};
        	   else
        	      mem.write_addr <= {tag_read.tag, cpu.write_addr[11:0]};
        	   if(!mem.write_addr_ready)
        	      next_state <= writeback;
        	   else 
        	   begin
        	   	  next_state <= allocate;
            	  tag_write <= tag_read;
        	   	  tag_req.we <= 1;
        	   	  tag_write.dirty <= 0;
        	   end
        	   end
//ALLOCATE (Read MEM)        
        allocate: 
        	begin
        	    mem.size <= 2'b00;
        	    mem.strobe <= 0;
        	   	mem.write_addr_valid <= 0;
        	   	mem.read_addr_valid <= 1;
        	    cpu.read_addr_ready <= 0;
        	   	cpu.write_addr_ready <= 0;
        	   	cpu.read_data_valid <= 0;
        	   	if (cpu.read_addr_valid)
        	       	mem.read_addr <= cpu.read_addr;
        	   	else
        	       	mem.read_addr <= cpu.write_addr;
        	   	if (!mem.read_data_valid) 
        	   	begin
        	       	next_state <= allocate;
        	       	mem.read_addr_valid <= 1;
        	   	end
        	   	else  
        	   	begin
        	       	next_state = save;
        	       	mem.read_addr_valid <= 0;
        	   	end
        	    end
 //SAVE IN CACHE       	    
        save: 
        	begin
        	   	mem.read_addr_valid <= 0;
        	   	mem.write_addr_valid <= 0;
        	   	cpu.read_addr_ready <= 0;
        	   	cpu.write_addr_ready <= 0;
        	   	cpu.read_data_valid <= 0;
        	    
        	    if (cpu.read_addr_valid)
        	       	mem.read_addr <= cpu.read_addr[31:4];
        	   	else
        	       	mem.read_addr <= cpu.write_addr[31:4];
        	   
        	   	next_state <= compare_tag;
        	   	i = {2'b0, cpu.read_addr_valid ? cpu.read_addr[11:4] : cpu.write_addr[11:4]};
        	   	data_req.index <= i;
        	   	data_req.we <= 1;
        	   	data_write <= mem.read_data;
        	   	
        	   	tag_req.index <= i;
        	   	tag_req.we <= 1;
        	   	tag_write.tag <= cpu.read_addr_valid ? cpu.read_addr[31:12] : cpu.write_addr[31:12];
        	   	tag_write.valid <= 1;
        	   	tag_write.dirty <= 0;
        	   	
        	   	from_ram = 1;
        	   	cpu.read_data_valid = 1;
        	    end
            default:
        	    next_state = compare_tag;
        	endcase
        	end
//FSM for Cache Controller 
	L1_cache_tag L1_tags(.*);
	L1_cache_data L1_data(.*);
 
endmodule
