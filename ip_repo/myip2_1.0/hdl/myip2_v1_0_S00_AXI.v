
`timescale 1 ns / 1 ps

	module myip2_v1_0_S00_AXI #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line

		// Width of S_AXI data bus
		parameter integer C_S_AXI_DATA_WIDTH	= 32,
		// Width of S_AXI address bus
		parameter integer C_S_AXI_ADDR_WIDTH	= 4
	)
	(
		// Users to add ports here

		// User ports ends
		// Do not modify the ports beyond this line

		// Global Clock Signal
		input wire  S_AXI_ACLK,
		// Global Reset Signal. This Signal is Active LOW
		input wire  S_AXI_ARESETN,
		// Write address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
		// Write channel Protection type. This signal indicates the
    		// privilege and security level of the transaction, and whether
    		// the transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_AWPROT,
		// Write address valid. This signal indicates that the master signaling
    		// valid write address and control information.
		input wire  S_AXI_AWVALID,
		// Write address ready. This signal indicates that the slave is ready
    		// to accept an address and associated control signals.
		output wire  S_AXI_AWREADY,
		// Write data (issued by master, acceped by Slave) 
		input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
		// Write strobes. This signal indicates which byte lanes hold
    		// valid data. There is one write strobe bit for each eight
    		// bits of the write data bus.    
		input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
		// Write valid. This signal indicates that valid write
    		// data and strobes are available.
		input wire  S_AXI_WVALID,
		// Write ready. This signal indicates that the slave
    		// can accept the write data.
		output wire  S_AXI_WREADY,
		// Write response. This signal indicates the status
    		// of the write transaction.
		output wire [1 : 0] S_AXI_BRESP,
		// Write response valid. This signal indicates that the channel
    		// is signaling a valid write response.
		output wire  S_AXI_BVALID,
		// Response ready. This signal indicates that the master
    		// can accept a write response.
		input wire  S_AXI_BREADY,
		// Read address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
		// Protection type. This signal indicates the privilege
    		// and security level of the transaction, and whether the
    		// transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_ARPROT,
		// Read address valid. This signal indicates that the channel
    		// is signaling valid read address and control information.
		input wire  S_AXI_ARVALID,
		// Read address ready. This signal indicates that the slave is
    		// ready to accept an address and associated control signals.
		output wire  S_AXI_ARREADY,
		// Read data (issued by slave)
		output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
		// Read response. This signal indicates the status of the
    		// read transfer.
		output wire [1 : 0] S_AXI_RRESP,
		// Read valid. This signal indicates that the channel is
    		// signaling the required read data.
		output wire  S_AXI_RVALID,
		// Read ready. This signal indicates that the master can
    		// accept the read data and response information.
		input wire  S_AXI_RREADY
	);

	// AXI4LITE signals
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
	reg  	axi_awready;
	reg  	axi_wready;
	reg [1 : 0] 	axi_bresp;
	reg  	axi_bvalid;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
	reg  	axi_arready;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] 	axi_rdata;
	reg [1 : 0] 	axi_rresp;
	reg  	axi_rvalid;

	// Example-specific design signals
	// local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	// ADDR_LSB is used for addressing 32/64 bit registers/memories
	// ADDR_LSB = 2 for 32 bits (n downto 2)
	// ADDR_LSB = 3 for 64 bits (n downto 3)
	localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
	localparam integer OPT_MEM_ADDR_BITS = 1;
	//----------------------------------------------
	//-- Signals for user logic register space example
	//------------------------------------------------
	//-- Number of Slave Registers 4
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg0;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg1;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg2;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg3;
	wire	 slv_reg_rden;
	wire	 slv_reg_wren;
	reg [C_S_AXI_DATA_WIDTH-1:0]	 reg_data_out;
	integer	 byte_index;

	// I/O Connections assignments

	assign S_AXI_AWREADY	= axi_awready;
	assign S_AXI_WREADY	= axi_wready;
	assign S_AXI_BRESP	= axi_bresp;
	assign S_AXI_BVALID	= axi_bvalid;
	assign S_AXI_ARREADY	= axi_arready;
	assign S_AXI_RDATA	= axi_rdata;
	assign S_AXI_RRESP	= axi_rresp;
	assign S_AXI_RVALID	= axi_rvalid;
	// Implement axi_awready generation
	// axi_awready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
	// de-asserted when reset is low.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awready <= 1'b0;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID)
	        begin
	          // slave is ready to accept write address when 
	          // there is a valid write address and write data
	          // on the write address and data bus. This design 
	          // expects no outstanding transactions. 
	          axi_awready <= 1'b1;
	        end
	      else           
	        begin
	          axi_awready <= 1'b0;
	        end
	    end 
	end       

	// Implement axi_awaddr latching
	// This process is used to latch the address when both 
	// S_AXI_AWVALID and S_AXI_WVALID are valid. 

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awaddr <= 0;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID)
	        begin
	          // Write Address latching 
	          axi_awaddr <= S_AXI_AWADDR;
	        end
	    end 
	end       

	// Implement axi_wready generation
	// axi_wready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
	// de-asserted when reset is low. 

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_wready <= 1'b0;
	    end 
	  else
	    begin    
	      if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID)
	        begin
	          // slave is ready to accept write data when 
	          // there is a valid write address and write data
	          // on the write address and data bus. This design 
	          // expects no outstanding transactions. 
	          axi_wready <= 1'b1;
	        end
	      else
	        begin
	          axi_wready <= 1'b0;
	        end
	    end 
	end       

	// Implement memory mapped register select and write logic generation
	// The write data is accepted and written to memory mapped registers when
	// axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
	// select byte enables of slave registers while writing.
	// These registers are cleared when reset (active low) is applied.
	// Slave register write enable is asserted when valid address and data are available
	// and the slave is ready to accept the write address and write data.
	assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      slv_reg0 <= 0;
	      slv_reg1 <= 0;
//	      slv_reg2 <= 0;
//	      slv_reg3 <= 0;
	    end 
	  else begin
	    if (slv_reg_wren)
	      begin
	        case ( axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	          2'h0:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 0
	                slv_reg0[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          2'h1:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 1
	                slv_reg1[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          2'h2:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 2
//	                slv_reg2[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          2'h3:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 3
//	                slv_reg3[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          default : begin
	                      slv_reg0 <= slv_reg0;
	                      slv_reg1 <= slv_reg1;
	                      slv_reg2 <= slv_reg2;
	                      slv_reg3 <= slv_reg3;
	                    end
	        endcase
	      end
	  end
	end    

	// Implement write response logic generation
	// The write response and response valid signals are asserted by the slave 
	// when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
	// This marks the acceptance of address and indicates the status of 
	// write transaction.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_bvalid  <= 0;
	      axi_bresp   <= 2'b0;
	    end 
	  else
	    begin    
	      if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
	        begin
	          // indicates a valid write response is available
	          axi_bvalid <= 1'b1;
	          axi_bresp  <= 2'b0; // 'OKAY' response 
	        end                   // work error responses in future
	      else
	        begin
	          if (S_AXI_BREADY && axi_bvalid) 
	            //check if bready is asserted while bvalid is high) 
	            //(there is a possibility that bready is always asserted high)   
	            begin
	              axi_bvalid <= 1'b0; 
	            end  
	        end
	    end
	end   

	// Implement axi_arready generation
	// axi_arready is asserted for one S_AXI_ACLK clock cycle when
	// S_AXI_ARVALID is asserted. axi_awready is 
	// de-asserted when reset (active low) is asserted. 
	// The read address is also latched when S_AXI_ARVALID is 
	// asserted. axi_araddr is reset to zero on reset assertion.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_arready <= 1'b0;
	      axi_araddr  <= 32'b0;
	    end 
	  else
	    begin    
	      if (~axi_arready && S_AXI_ARVALID)
	        begin
	          // indicates that the slave has acceped the valid read address
	          axi_arready <= 1'b1;
	          // Read address latching
	          axi_araddr  <= S_AXI_ARADDR;
	        end
	      else
	        begin
	          axi_arready <= 1'b0;
	        end
	    end 
	end       

	// Implement axi_arvalid generation
	// axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
	// S_AXI_ARVALID and axi_arready are asserted. The slave registers 
	// data are available on the axi_rdata bus at this instance. The 
	// assertion of axi_rvalid marks the validity of read data on the 
	// bus and axi_rresp indicates the status of read transaction.axi_rvalid 
	// is deasserted on reset (active low). axi_rresp and axi_rdata are 
	// cleared to zero on reset (active low).  
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rvalid <= 0;
	      axi_rresp  <= 0;
	    end 
	  else
	    begin    
	      if (axi_arready && S_AXI_ARVALID && ~axi_rvalid)
	        begin
	          // Valid read data is available at the read data bus
	          axi_rvalid <= 1'b1;
	          axi_rresp  <= 2'b0; // 'OKAY' response
	        end   
	      else if (axi_rvalid && S_AXI_RREADY)
	        begin
	          // Read data is accepted by the master
	          axi_rvalid <= 1'b0;
	        end                
	    end
	end    

	// Implement memory mapped register select and read logic generation
	// Slave register read enable is asserted when valid address is available
	// and the slave is ready to accept the read address.
	assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;
	always @(*)
	begin
	      // Address decoding for reading registers
	      case ( axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	        2'h0   : reg_data_out <= slv_reg0;
	        2'h1   : reg_data_out <= slv_reg1;
	        2'h2   : reg_data_out <= slv_reg2;
	        2'h3   : reg_data_out <= slv_reg3;
	        default : reg_data_out <= 0;
	      endcase
	end

	// Output register or memory read data
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rdata  <= 0;
	    end 
	  else
	    begin    
	      // When there is a valid read address (S_AXI_ARVALID) with 
	      // acceptance of read address by the slave (axi_arready), 
	      // output the read dada 
	      if (slv_reg_rden)
	        begin
	          axi_rdata <= reg_data_out;     // register read data
	        end   
	    end
	end    


	// Add user logic here
    wire ARESET;
    assign ARESET = ~S_AXI_ARESETN;
    
    // Transfer output from cordic processor to output registers
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_wire2;
    wire [C_S_AXI_DATA_WIDTH-1:0] slv_wire3;
    
    always @( posedge S_AXI_ACLK )
    begin
        slv_reg2 <= slv_wire2;
        slv_reg3 <= slv_wire3;
    end
    
    // Assign zeros to unused bits
//    assign slv_wire2[31:2] = 31'b0;
    
    coder coder_inst(
        S_AXI_ACLK, // clock,  
        ARESET, // reset, 
        slv_reg0[0],        // clockEable,
        slv_reg0[1],        // messageLoaded, 
        slv_reg0[2],        // dataLoaded, 
        slv_reg0[3],        // manualReset, 
        slv_reg0[15:8],     // symbol, 
        slv_reg1[31:0],     // symbolLength, 
        slv_reg0[23:16],    // character, 
        slv_reg0[31:24],    // message,
        slv_wire2[15:0],    // dataReady,
        slv_wire3[15:0],    // dataOut
        slv_wire3[31:16]    // log
    ); 
    
	// User logic ends

	endmodule
	
    module coder(
    input  clock,  
    input  reset, 
    input  clockEnable,
    input  messageLoaded, 
    input  dataLoaded, 
    input  manualReset,
    input  [7:0] symbol, 
    input  [31:0] symbolLength, 
    input  [7:0] character, 
    input  [7:0] message,
    output reg [15:0] dataReady,
    output reg [31:0] dataOut,
    output reg [15:0] log
);


//State machine
reg [3:0] stateMachine;
parameter M_RESET = 4'h01, M_LOAD_DATA = 4'h02, M_PARSE_DATA = 4'h03, M_ADD_BITS_COUNT = 4'h04, M_DATA_PUSH = 4'h05, M_DATA_CLEAR = 4'h06;

reg [3:0] loadDataMachine;
reg [3:0] pushDataMachine;
parameter DETECT_EDGE = 4'h01, EDGE_DETECTED = 4'h02, HIGH_EDGE = 4'h03, INCREMENT_K = 4'h04;

reg [4:0] parseDataMachine;
parameter INCREMENT_J = 5'h01, GET_ACTUAL_CHARACTER = 5'h02, GET_CHARACTER_INDEX = 5'h03, GET_SYMBOL_LENGTH = 5'h04, CALCULATE_BIT_SHIFT = 5'h05,
CHECK_BIT_SHIFT = 5'h06, RECALCULATE_BIT_SHIFT = 5'h07, APPLY_NEW_BIT_SHIFT = 5'h08, CHECK_J = 5'h09, INCREMENT_BYTES_INDEX = 5'h0A;

reg [3:0] clearDataMachine;
parameter CLEAR_BYTE = 4'h01, INCREMENT_I = 4'h02;
//parameter P_DETECT_EDGE = 4'h01, P_EDGE_DETECTED = 4'h02, HIGH_EDGE = 4'h03, INCREMENT_K = 4'h04;

// iterators
reg [31:0] i = 32'h0;
reg [31:0] k = 32'h0;
reg [31:0] j = 32'h0;  

// detecting clock data change  
reg previousClockEnable;

parameter BUFFER_SIZE = 100;
// buffers for input data
reg [7:0] allMessage[0:BUFFER_SIZE-1];
reg [7:0] symbols[0:BUFFER_SIZE-1];
reg [31:0] symbolsLength[0:BUFFER_SIZE-1];
reg [7:0] characters[0:BUFFER_SIZE-1];

// buffer for putput data
reg [31:0] outputBits [0:BUFFER_SIZE-1];
integer allBitsCount;

// variables for proper working
reg [7:0] actualCharacterMessage;
reg [7:0] actualCharacterSymbolLength;
reg [31:0] actualCharacterSymbol;
reg [7:0] characterIndex;
reg [7:0] outBytesIndex;
reg [7:0] positive;
integer bitShift;


initial
begin
   stateMachine <= M_RESET;
end
    
always @(posedge clock) begin
    log <= stateMachine;
    if (manualReset) begin 
        stateMachine <= M_RESET;
    end
    if(reset || stateMachine == M_RESET) begin
        stateMachine <= M_LOAD_DATA;
        i <= 0;
        j <= 0;
        k <= 0;
        dataReady <= 0;
        dataOut <= 0;
        bitShift <= 16;
        outBytesIndex <= 0;
        allBitsCount <= 0;
        loadDataMachine <= DETECT_EDGE;
        parseDataMachine <= INCREMENT_J;
        pushDataMachine <= DETECT_EDGE;
        clearDataMachine <= CLEAR_BYTE;
        positive <= 0;
        actualCharacterSymbolLength <= 0;
        characterIndex <= 0;
        actualCharacterMessage <= 0;
        actualCharacterSymbol <= 0;
        previousClockEnable <= 0;
        outputBits[0] <= 0;
     end else begin
        case(stateMachine)
            M_LOAD_DATA: begin
                case(loadDataMachine)
                    DETECT_EDGE: begin
                        if (clockEnable != previousClockEnable) begin
                            previousClockEnable <= clockEnable;
                            loadDataMachine <= EDGE_DETECTED;
                        end else begin
                            loadDataMachine <= DETECT_EDGE;
                        end
                    end
                    
                    EDGE_DETECTED: begin
                        if (clockEnable) begin
                            loadDataMachine <= HIGH_EDGE;
                        end else begin
                            loadDataMachine <= DETECT_EDGE;
                        end
                    end 
                    
                    HIGH_EDGE: begin
                        if (!dataLoaded) begin
                            symbolsLength[k] <= symbolLength;
                            symbols[k] <= symbol;
                            characters[k] <= character;
                        end
                        
                        if (!messageLoaded) begin
                            allMessage[k] <= message;
                        end
                        
                        if(dataLoaded && messageLoaded) begin
                            stateMachine <= M_PARSE_DATA;
                            loadDataMachine <= DETECT_EDGE;
                            previousClockEnable <= 0;
                            k <= 0;
                        end else begin
                            loadDataMachine <= INCREMENT_K;
                        end
                    end
                    
                    INCREMENT_K: begin
                        k <= k + 1;
                        loadDataMachine <= DETECT_EDGE;
                    end
                endcase
            end
            
            M_PARSE_DATA: begin
                case(parseDataMachine)
                    INCREMENT_J: begin
                        j <= j + 1;
                        parseDataMachine <= CHECK_J;
                    end
                    
                    CHECK_J: begin
                        if (j < allMessage[0]) begin 
                            parseDataMachine <= GET_ACTUAL_CHARACTER;
                        end else begin
                            parseDataMachine <= INCREMENT_J;
                            j <= 0;
                            stateMachine <= M_ADD_BITS_COUNT;
                        end
                    end
                    
                    GET_ACTUAL_CHARACTER: begin
                        actualCharacterMessage <= allMessage[j];
                        parseDataMachine <= GET_CHARACTER_INDEX;
                    end
                    
                    GET_CHARACTER_INDEX: begin
                        if (actualCharacterMessage == 32) begin // spacja
                            characterIndex <= 1;
                        end else begin
                            characterIndex <= actualCharacterMessage - 63;
                        end
                        parseDataMachine <= GET_SYMBOL_LENGTH;
                    end
                    
                    GET_SYMBOL_LENGTH: begin
                        actualCharacterSymbolLength <= symbolsLength[characterIndex];
                        parseDataMachine <= CALCULATE_BIT_SHIFT;
                    end
                    
                    CALCULATE_BIT_SHIFT: begin
                        bitShift <= bitShift - actualCharacterSymbolLength;
                        allBitsCount <= allBitsCount + actualCharacterSymbolLength;
                        parseDataMachine <= CHECK_BIT_SHIFT;
                    end
                    
                    CHECK_BIT_SHIFT: begin
                        if (bitShift < 0) begin
                            outputBits[outBytesIndex + 1] <= 0;
                            positive <= -bitShift;
                            parseDataMachine <= RECALCULATE_BIT_SHIFT;
                        end else begin
                            outputBits[outBytesIndex] <= outputBits[outBytesIndex] | (symbols[characterIndex] << bitShift);
                            parseDataMachine <= INCREMENT_J;
                        end
                    end
                  
                    RECALCULATE_BIT_SHIFT: begin
                        outputBits[outBytesIndex] <= outputBits[outBytesIndex] | ( symbols[characterIndex] >> positive);
                        bitShift <= 32 - positive;
                        parseDataMachine <= INCREMENT_BYTES_INDEX;
                    end
                    
                    INCREMENT_BYTES_INDEX: begin
                        outBytesIndex <= outBytesIndex + 1;
                        parseDataMachine <= APPLY_NEW_BIT_SHIFT;
                    end
                    
                    APPLY_NEW_BIT_SHIFT: begin
                        outputBits[outBytesIndex] <= outputBits[outBytesIndex] | (symbols[characterIndex] << bitShift);
                        parseDataMachine <= INCREMENT_J;
                    end
                
                endcase
            end
            
            M_ADD_BITS_COUNT: begin
                outputBits[0] <= outputBits[0] | (allBitsCount << 16);
                dataReady <= 1;
                stateMachine <= M_DATA_PUSH;
            end
            
            M_DATA_PUSH: begin
                case(pushDataMachine)
                    DETECT_EDGE: begin
                        if (clockEnable != previousClockEnable) begin
                            previousClockEnable <= clockEnable;
                            pushDataMachine <= EDGE_DETECTED;
                        end else begin
                            pushDataMachine <= DETECT_EDGE;
                        end
                    end
                    
                    EDGE_DETECTED: begin
                        if (clockEnable) begin
                            pushDataMachine <= HIGH_EDGE;
                        end else begin
                            pushDataMachine <= DETECT_EDGE;
                        end
                    end 
                    
                    HIGH_EDGE: begin
                        if(k > outBytesIndex) begin
                            stateMachine <= M_DATA_CLEAR;
                            k <= 0;
                            dataOut <= 0;
                            pushDataMachine <= DETECT_EDGE;
                        end else begin
                            dataOut <= outputBits[k];
                            dataReady <= k;
                            pushDataMachine <= INCREMENT_K;
                        end
                    end
                    
                    INCREMENT_K: begin
                        k <= k + 1;
                        pushDataMachine <= DETECT_EDGE;
                    end
                endcase               
            end  
            
            M_DATA_CLEAR: begin
                case(clearDataMachine) 
                    CLEAR_BYTE: begin
                        if (i < BUFFER_SIZE) begin
                            allMessage[i] <= 0;
                            symbols[i] <= 0;
                            symbolsLength[i] <= 0;
                            characters[i] <= 0;
                            outputBits[i] <= 0;
                            clearDataMachine <= INCREMENT_I;
                        end else begin
                            clearDataMachine <= CLEAR_BYTE;
                            i <= 0;
                            stateMachine <= M_RESET;
                        end
                    end
                    
                    INCREMENT_I: begin
                        i <= i + 1;
                        clearDataMachine <= CLEAR_BYTE;
                    end
                endcase
            end   
        endcase
     end
 end
endmodule