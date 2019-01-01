`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Andrew Capon
// 
// Create Date: 11/25/2018 11:36:55 AM
// Design Name: FanControl
// Module Name: FanControl
// Project Name: FanControl
// Target Devices: Ultra96
// Tool Versions: Vivado 2018.2
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////



`include "Defines.v"

module FanControl(
    input            clk_in_100,
    input            rst_n_in,
    input `Unsigned  raw_temp_in,
    input `Unsigned  low_temp_in,
    input `Unsigned  high_temp_in,
    input `Unsigned  smooth_divisor_in,
    input `Unsigned  forced_PWM_in,
    input            temp_alarm_in,
    
    output reg              PWM_out,
    output wire `Unsigned   real_temp_out,
    output reg [31:0]       dbg_out [15:0]
    
    );
    
    function `UFixed toUFixed;
        input `Unsigned u;
        begin
            toUFixed = u << `FixedFractionalBits;
        end
    endfunction
    
    
    function `Unsigned fromUFixed;
        input `UFixed f;
        begin
            fromUFixed = (f + `FixedHalf) >> `FixedFractionalBits;
        end
    endfunction
    
    
    function `UFixed mulUFixed;
        input `UFixed f1, f2;
        begin
            mulUFixed = (f1 * f2) >> `FixedFractionalBits; 
        end
    endfunction
    

    function `UFixed divUFixed;
        input `UFixed f1, f2;
        begin
            divUFixed = (f1 << `FixedFractionalBits) / f2;
        end
    endfunction
    
    
    
    function `UFixed transition;
        input `UFixed fLast, fNew, fRatio;
        reg `UFixed fDiff;
        reg `UFixed fDiffSmoothed;
        begin
            if((fRatio == 0) || (fRatio==1) || (fLast == fNew))
                transition = fNew;
            else
                if(fLast > fNew)
                   begin
                      fDiff = fLast - fNew;
                      fDiffSmoothed = divUFixed((fDiff), fRatio);
                      transition = fLast - fDiffSmoothed;
                    end
                else
                   begin
                      fDiff = fNew - fLast;
                      fDiffSmoothed = divUFixed((fDiff), fRatio);
                      transition = fLast + fDiffSmoothed;
                   end
        end
    endfunction

 
    
   wire PWM;
   wire processing_clk;
   
   reg `Unsigned u_temp_range; 
   reg `Unsigned u_real_temp;
   reg `UFixed uf_low_temp;
   reg `UFixed uf_high_temp;
   reg `UFixed uf_real_temp;
   reg `UFixed uf_use_temp;
   reg `UFixed uf_last_temp;
   reg `UFixed uf_temp_range;
   
   reg `UFixed uf_smooth_divisor;


   reg `UFixed uf_use_PWM;
   reg `UFixed uf_temp_error;
   reg `UFixed uf_linear;
   reg `UFixed uf_PWM;
   reg `UFixed uf_max_PWM;
   reg `UFixed uf_last_PWM;
   reg [11:0] PWM_value;

   
   assign real_temp_out = u_real_temp;
   
   ClockDivider clockDivider(
       .clk_in(clk_in_100),
       .rst_n_in(rst_n_in),
       .divider_in(50000),
       .clk_out(processing_clk)
       );


   
   PWM pwm(
         .clk_in(clk_in_100),
         .rst_n_in(rst_n_in),
         .val_in(PWM_value),
         .PWM_out(PWM)
         );



   initial
   begin
     uf_last_temp = toUFixed(8500);  // Reset last temp to max temp
     uf_last_PWM = toUFixed(4095);   // Reset last PWM to max PWM
     uf_max_PWM = toUFixed(4095);
     dbg_out[0] = 0;
   end


    // temperature
    always@ (posedge processing_clk)
    begin
         uf_last_temp = uf_use_temp;
          
         u_temp_range = high_temp_in - low_temp_in;
           
         // convert params to unsigned fixed
         uf_low_temp = toUFixed(low_temp_in);
         uf_high_temp = toUFixed(high_temp_in);
         uf_temp_range = uf_high_temp - uf_low_temp;
         uf_smooth_divisor = toUFixed(smooth_divisor_in);
           
           // calculate the real temp from raw value
         u_real_temp = (((raw_temp_in * 50291) / 65536) - 27382);
         uf_real_temp = toUFixed(u_real_temp);
           
         // calculate smoothed temp to use
         uf_use_temp = transition(uf_last_temp, uf_real_temp, uf_smooth_divisor);
         //uf_use_temp = uf_real_temp;
      
    end;
    
    localparam FAN_OFF=0, FAN_PROCESS=1, FAN_ON=2, FAN_FORCED=3;
    reg [1:0] state = FAN_ON,    // Current state
              nxtState = FAN_ON; // Next state
    always @(posedge processing_clk) 
    begin
        if ((rst_n_in == 1'b0) ||  (temp_alarm_in == 1'b1))
            state <= FAN_ON;   // Fan full on when reset or alarm is set
        else
            state <= nxtState;
    end

    // next state function
    always@ (posedge processing_clk)
    begin
        nxtState = state;
        
        case (state)
            FAN_OFF :
                begin
                    if(forced_PWM_in != 0)
                        nxtState = FAN_FORCED;
                    else if(uf_use_temp >= uf_high_temp)
                        nxtState = FAN_ON;
                    else if(uf_use_temp >= uf_low_temp)
                        nxtState = FAN_PROCESS;
                end
                
            FAN_PROCESS :
                begin
                    if(forced_PWM_in != 0)
                        nxtState = FAN_FORCED;
                    else if(uf_use_temp >= uf_high_temp)
                        nxtState = FAN_ON;
                    else if(uf_use_temp < uf_low_temp)
                        nxtState = FAN_OFF;
                end
                
            FAN_ON :
                begin
                    if(forced_PWM_in != 0)
                        nxtState = FAN_FORCED;
                    else if(uf_use_temp < uf_high_temp)
                    begin
                        if(uf_use_temp >= uf_low_temp)
                            nxtState = FAN_PROCESS;
                        else
                            nxtState = FAN_OFF;
                    end;
                end
                
             FAN_FORCED:
                begin
                    if(forced_PWM_in == 0)
                        nxtState = FAN_PROCESS;
                end
        endcase            
    end;
   
    // output function
    always@ (posedge processing_clk)
    begin
        uf_last_PWM = uf_use_PWM;
    
        case (state)
            FAN_OFF :
                begin
                    uf_PWM = 0;                                
                end
               
            FAN_PROCESS :
                begin
                    if(uf_use_temp > uf_low_temp)
                    begin
                        uf_temp_error  = ( uf_use_temp - uf_low_temp);
                        uf_linear = divUFixed(uf_temp_error, uf_temp_range);
                        uf_PWM = mulUFixed(uf_max_PWM, uf_linear);
                    end
                    else
                        uf_PWM = 0;
                end
               
            FAN_ON :
                begin
                    uf_PWM = uf_max_PWM;                                
                end
                
            FAN_FORCED:
                begin
                    uf_PWM = toUFixed(forced_PWM_in[11:0]);
                end
        endcase      
        
        uf_use_PWM = transition(uf_last_PWM, uf_PWM, uf_smooth_divisor);
        PWM_value = fromUFixed(uf_use_PWM);
    end;
   
   
    // PWM signal out
    always@ (posedge clk_in_100)
    begin
        if (rst_n_in == 1'b0)              // FAN full on on reset
            PWM_out = 1'b1;
        else if  (temp_alarm_in == 1'b1)   // FAN full on on user temperature alarm
            PWM_out = 1'b1;
        else
            PWM_out = PWM;    
    end


    // debug registers
    always@ (posedge clk_in_100)
    begin
        dbg_out[0] = state;
        dbg_out[1] = uf_PWM;
        dbg_out[2] = uf_use_PWM;
        dbg_out[3] = uf_last_PWM;
             
        dbg_out[4] = uf_real_temp;
        dbg_out[5] = uf_use_temp;
        dbg_out[6] = uf_last_temp;
             
        dbg_out[7] = uf_temp_error;
        dbg_out[8] = uf_linear;
             
        dbg_out[9] = uf_max_PWM;

    end;
        
 endmodule      
         
