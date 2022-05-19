`timescale 1ns / 1ps

module OTTER_MCU(
    input logic RST, INTR, CLK,
    input logic [31:0] IOBUS_IN,
    
    output logic IOBUS_WR,
    output [31:0] IOBUS_OUT, IOBUS_ADDR // out is rs2, addr is alu resultant
    ); 
   
    //------------------ Wire Declerations-----------------------------//
    
    wire PCWrite_sig, regWrite_sig, regWrite_sig_execute, regWrite_sig_memory, regWrite_sig_writeback, memWE2_sig, memWE2_sig_execute, memWE2_sig_memory, memRDEN1_sig, memRDEN2_sig, reset_sig, memRDEN2_sig_execute, memRDEN2_sig_memory,
     csr_WE_sig, int_taken_sig, alu_srcA_sig, mem_SIGN, br_eq_signal, br_lt_signal,
     br_ltu_signal, IOBUS_WR_sig, MIE_sig, INTR_sig, button_sig;
    wire [1:0] alu_srcB_sig, rf_wr_sel_sig, mem_SIZE, rf_wr_sel_sig_execute, rf_wr_sel_sig_memory, rf_wr_sel_sig_writeback;
    wire [3:0] alu_fun_sig, alu_fun_sig_execute;
    wire [2:0] pcSource_sig, pcSOURCE_PIPE;
    wire [31:0] mux_PC, PC_output_signal, PC_plus_4, PC_plus_4_decode, PC_plus_4_execute, PC_plus_4_memory, PC_plus_4_writeback,
                mux_regfile, DOUT1_signal, DOUT2_regfile_writeback,
                DOUT2_regfile_mux, rs1_signal, rs2_signal, rs2_signal_execute, rs2_signal_memory, ALU_RESULT, regfile_rs2_memory,
                U_type_imm_signal, I_type_imm_signal, S_type_imm_signal,J_type_imm_signal, B_type_imm_signal,
                CSR_RD_signal, srcA_mux_ALU_signal, srcB_mux_ALU_signal, jal_signal, branch_signal, jalr_signal,
                mtvec_signal, mepc_signal, memory_output_SIG, memory_output_SIG_execute, memory_output_SIG_memory, memory_output_SIG_writeback, ALU_RESULT_MEM, ALU_RESULT_WRITEBACK;
    wire [13:0] PC_Memory;            
    //-------------------High Level Control Units-----------------------//
    debounce_one_shot intr0(.CLK(CLK), .BTN(INTR), 
                            .DB_BTN(button_sig));
    CSR_Component u0(.RST(reset_sig), .INT_TAKEN(int_taken_sig), .ADDR(DOUT1_signal), .WR_EN(csr_WE_sig), .clk(CLK), .PC(PC_output_signal), .WD(rs1_signal),
                        .mie(MIE_sig), .mepc(mepc_signal), .mtvec(mtvec_signal), .RD(CSR_RD_signal));
                        
    //*************************NEED TO REMOVE CONTROL FSM AND REPLACE WITH CONTROL SIGNALS FROM DECODER***************************//                    
    //control_unit_FSM u1(.clk_FSM(CLK), .INTR_FSM(INTR_sig), .RST_FSM(RST), // FSM Inputs
     //.OP_FSM(DOUT1_signal[6:0]),.FUNCT_FSM(DOUT1_signal[14:12]),
     
     //.PCWrite(PCWrite_sig), .regWrite(regWrite_sig), .memWE2(memWE2_sig), .memRDEN1(memRDEN1_sig),  //FSM outputs
     //.memRDEN2(memRDEN2_sig), .reset(reset_sig), .csr_WE(csr_WE_sig), .int_taken(int_taken_sig));
    //***************************** disabled 2/19/2022 ***********************************************************//
      
    //------------Lower Level circuits-----------------------------------//
    
    //*************INTERRUPT BUTTON NOT NEEDED***************************//
    INTR_button b0(.button(button_sig), .csr_mie(MIE_sig),
                    .INTR_OUT(INTR_sig));
    //*******************************************************************//   


    //********************** FETCH *************************************//
    assign PCWrite_sig = 1'b1;                         // set PCWRITE signal to constant high
    PCincrement P3(.PC_out(PC_output_signal), 
                   .PC_incremented(PC_plus_4));
   PC_mux m1(.PC_next(PC_plus_4), .jalr(jalr_signal), .branch(branch_signal), .jal(jal_signal), .mtvec(mtvec_signal), //pc mux inputs
             .mepc(mepc_signal), .pcSource(pcSOURCE_PIPE),   // pc mux outputs
             .muxpc_output(mux_PC));
   PC p1(.reset(RST), .PCWrite(1'b1), .PC_DIN(mux_PC), .CLK(CLK),  // pc inputs
         .PC_COUNT(PC_output_signal));                                          // pc outputs
         
   memory_wire_adjust p4(.PC_address(PC_output_signal),
                          .MEM_ADDR1_adjust(PC_Memory));
   
   assign memRDEN1_sig = 1;                            // set memRDEN1 signal to constant high
   Memory c1(.MEM_CLK(CLK), .MEM_RDEN1(memRDEN1_sig), .MEM_RDEN2(memRDEN2_sig), .MEM_WE2(memWE2_sig),       // Memory inputs
        .MEM_ADDR1(PC_Memory), .MEM_ADDR2(ALU_RESULT), 
        .MEM_SIGN(DOUT1_signal[14]), .IO_IN(IOBUS_IN),
        .MEM_DOUT1(DOUT1_signal));                  // memory outputs
    //****************************************************************//    
    
   Fetch_pipeline pipe1(.CLK(CLK), .memory_input(DOUT1_signal), .PC_plus_4_in(PC_plus_4),
    .memory_output(memory_output_SIG), .PC_plus_4_out(PC_plus_4_decode));
  
    //************************ Decode ********************************//
    reg_file c2(.input_register(memory_output_SIG), .RAM_CLK(CLK), // regfile inputs
                .rs1(rs1_signal), .rs2(rs2_signal));                                                          // regfile outputs
                
    CU_DCDR u2(.OP_DCDR(memory_output_SIG[6:0]), .FUNCT_DCDR(memory_output_SIG[14:12]),   // Decoder inputs
     .sign_DCDR(memory_output_SIG[30]), .int_taken_DCDR(int_taken_sig),
     .br_eq_DCDR(br_eq_signal), .br_lt_DCDR(br_lt_signal), .br_ltu_DCDR(br_ltu_signal),
     
     .alu_fun(alu_fun_sig), .alu_srcA(alu_srcA_sig), .alu_srcB(alu_srcB_sig),
     .pcSource(pcSource_sig), .rf_wr_sel(rf_wr_sel_sig),                        // decoder outputs
     .regWrite(regWrite_sig), .memWrite(memWE2_sig), .memRDEN2(memRDEN2_sig));
     
    imm_gen i1(.IR(memory_output_SIG),                                                                              // imm gen inputs
                .U_type(U_type_imm_signal), .I_type(I_type_imm_signal), 
                .S_type(S_type_imm_signal), .J_type(J_type_imm_signal), .B_type(B_type_imm_signal));            // imm gen outputs
      
    alu_muxA m3(.rs1_ALU(rs1_signal), .U_type_ALU(U_type_imm_signal), .alu_srcA_sel(alu_srcA_sig),
                .srcA(srcA_mux_ALU_signal));
    
    alu_muxB m4(.rs2_ALU(rs2_signal), .I_type_ALU(I_type_imm_signal), 
                .S_type_ALU(S_type_imm_signal), .PC_current_ALU(PC_output_signal), .alu_srcB(alu_srcB_sig),
                .srcB(srcB_mux_ALU_signal));
    //*****************************************************************//        
    
    EXECUTE_Pipeline pipe2(.CLK(CLK), .muxA_ouput(srcA_mux_ALU_signal), .muxB_output(srcB_mux_ALU_signal), .alu_fun(alu_fun_sig), . rf_wr_sel(rf_wr_sel_sig), .memRead2(memRDEN2_sig), 
    .memWrite(memWE2_sig), .regWrite(regWrite_sig), .pcSource(pcSource_sig), .memory_output_input(memory_output_SIG), .rs2_in(rs2_signal), .PC_plus_4_in(PC_plus_4_decode),// pcWrite wire will be fed back to PC on posedge
    
    .muxA_ouput_out(srcA_mux_ALU_signal), .muxB_output_out(srcB_mux_ALU_signal), .alu_fun_out(alu_fun_sig_execute), . rf_wr_sel_out(rf_wr_sel_sig_execute), .memRead2_out(memRDEN2_sig_execute), 
    .memWrite_out(memWE2_sig_execute), .regWrite_out(regWrite_sig_execute), .pcSource_out(pcSOURCE_PIPE), .memory_output_output(memory_output_SIG_execute), .rs2_out(rs2_signal_execute), .PC_plus_4_out(PC_plus_4_execute));
    
    //************************ Execute ********************************//
    Branch_Address_Gen b1(.PC_current(PC_output_signal), .Jtype_imm(J_type_imm_signal),             // brach address inputs
             .Btype_imm(B_type_imm_signal), .Itype_imm(I_type_imm_signal), .rs1_output(rs1_signal),
             .jal_output(jal_signal), .branch_output(branch_signal), .jalr_output(jalr_signal));
    
                
   Branch_Cond_Gen b2(.BranchCond_rs1(rs1_signal), .BranchCond_rs2(rs2_signal),
                      .br_eq(br_eq_signal), .br_lt(br_lt_signal), .br_ltu(br_ltu_signal));  
   
   ALU A1(.A(srcA_mux_ALU_signal), .B(srcB_mux_ALU_signal), .ALU_FUN(alu_fun_sig_execute), //ALU inputs
           .RESULT(ALU_RESULT));        // ALU outputs
   //*******************************************************************//
   
   MEMORY_pipeline p3(.CLK(CLK), .alu_in(ALU_RESULT), .rs2_in(rs2_signal_execute), .input_register_in(memory_output_SIG_execute), .rf_wr_sel(rf_wr_sel_sig_execute), 
   .memRead2(memRDEN2_sig_execute), .memWrite(memWE2_sig_execute), .regWrite(regWrite_sig_execute), .PC_plus_4_in(PC_plus_4_execute),
   
   .alu_out(ALU_RESULT_MEM), .rs2_out(rs2_signal_memory), .input_register_out(memory_output_SIG_memory), 
   .rf_wr_sel_out(rf_wr_sel_sig_memory), .memRead2_out(memRDEN2_sig_memory), .memWrite_out(memWE2_sig_memory), .regWrite_out(regWrite_sig_memory), .PC_plus_4_out(PC_plus_4_memory));
   
   //**************************** Memory *******************************//
    Memory mem2(.MEM_CLK(CLK), .MEM_RDEN2(memRDEN2_sig), .MEM_WE2(memWE2_sig_memory),       // Memory inputs
                .MEM_ADDR2(ALU_RESULT_MEM), 
                .MEM_DIN2(rs2_signal_memory), .MEM_SIZE(memory_output_SIG_memory[13:12]), .MEM_SIGN(memory_output_SIG_memory[14]), .IO_IN(IOBUS_IN),
                .IO_WR(IOBUS_WR_sig),.MEM_DOUT2(DOUT2_regfile_mux));                  // memory outputs
                
     assign IOBUS_OUT = rs2_signal_memory;   // assignment of ouputs
     assign IOBUS_ADDR = ALU_RESULT_WRITEBACK;
     assign IOBUS_WR = IOBUS_WR_sig;
   //*******************************************************************//
   
   WRITEBACK_pipeline pipe4(.CLK(CLK), .dout2_in(DOUT2_regfile_mux), .alu_in(ALU_RESULT_MEM), .input_register_in(memory_output_SIG_memory), .PC_plus_4_in(PC_plus_4_memory), .rf_wr_sel(rf_wr_sel_sig_memory), .regWrite(regWrite_sig_memory), 
   
   .dout2_out(DOUT2_regfile_writeback), .alu_out(ALU_RESULT_WRITEBACK), .input_register_out(memory_output_SIG_writeback), .PC_plus_4_out(PC_plus_4_writeback), .rf_wr_sel_out(rf_wr_sel_sig_writeback), .regWrite_out(regWrite_sig_writeback)
   );
   
   //************************** WriteBack ******************************//
    reg_file_mux m2(.PC_increment_REG_FILE(PC_plus_4_writeback), .CSR_RD_REGFILE(CSR_RD_signal),                        // reg_file wd mux inputs
                    .DOUT2_REG_FILE(DOUT2_regfile_writeback), .ALU_result_FILE(ALU_RESULT_WRITEBACK), .rf_wr_sel(rf_wr_sel_sig_writeback),
                    .wd_regFile(mux_regfile)); 
                    
                    
     reg_file c3(.input_register(memory_output_SIG_writeback), .RAM_CLK(CLK), .wd_value(mux_regfile), .regwrite(regWrite_sig_writeback)); // regfile inputs
                                                                              // reg file wd outputs
   //******************************************************************//
    
         
endmodule
