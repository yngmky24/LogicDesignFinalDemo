module test_final(
		input left, right, restart, respawn, start_g, stop, speed, choose_level,
		input CLK, 
		output [0:7] R1, G2, B3,
		output reg [3:0] COMM,
		output reg [0:3] life,
		output reg beep,
		output reg [0:6] score_led,
		output reg [1:0] score_COM
);
		 reg last_status_l = 1'b0, last_status_r = 1'b0;
		 reg last_status_respawn = 1'b0;
		 reg [2:0] remain_life =4;
		 reg [3:0] score = 4'b0;
		 reg start = 1'b0;
		 reg up = 1;
		 reg [1:0] ball_status;
		 reg a=0, b=0, c=0, d=0;
		 
		 reg [7:0] time_pass = 8'b0;
		 reg [7:0] ball_y = 8'b00000010;										// ball(y direction)
		 reg [2:0] ball_x = 3'b011;
		 reg [15:0] block = 16'b0100001001011010; 						// stage_block
		 reg stage_1 = 1;
		 reg [2:0] plat_1 = 3'b000, plat_2 = 3'b001, plat_3 = 3'b010;		// plat location
		 reg [2:0] kplat_1 = 3'b000, kplat_2 = 3'b001, kplat_3 = 3'b010;	// const plat location
		 reg [2:0] plat_pos = 3'b000;													// move plat(x direction)
		 reg ten_score = 0;
	parameter logic [7:0] WIN[0:7] =
		'{ 8'b11111111,
			8'b10000001,
			8'b11101101,
			8'b11011101,
			8'b11011101,
			8'b11101101,
			8'b10000001,
			8'b11111111
		};
	parameter logic [7:0] WIN2[0:7] =
	'{ 8'b10000000,
		8'b11101110,
		8'b11011110,
		8'b11101110,
		8'b11101110,
		8'b11011110,
		8'b11101110,
		8'b10000000
	};
	parameter logic [7:0] LOSE[0:7] =
		'{ 8'b01111110,
			8'b10111101,
			8'b11011011,
			8'b11100111,
			8'b11100111,
			8'b11011011,
			8'b10111101,
			8'b01111110
		};
	parameter logic [7:0] close[7:0] =
		'{ 8'b11111111,
			8'b11111111,
			8'b11111111,
			8'b11111111,
			8'b11111111,
			8'b11111111,
			8'b11111111,
			8'b11111111
		};
	bit[2:0] cnt;
	initial
		begin
			cnt = 0;					// 3'b000
			COMM = 4'b1000;
			score_led = 7'b1000000;
			score_COM[0] = 1'b0;
			score_COM[1] = 1'b1;
		end
	divfreq F0(CLK, CLK_ndiv);
	divfreq2 F1(CLK, CLK_fdiv);
	reg CLK_div;
	always @(speed or CLK_ndiv or CLK_fdiv)
		if(~speed) CLK_div = CLK_ndiv;		// normal speed
		else CLK_div = CLK_fdiv;				// fast speed

	always @(posedge CLK_div)
		begin
			if(cnt >= 7)	cnt = 0;	// 3'b000
			else	cnt = cnt + 1;		// 3'b001 ...
			COMM = {1'b1, cnt};		// 4'b1000 ...
			// 除頻部分 
			time_pass <= time_pass + 1'b1;
			
			// Win
			if(block == 16'b0)
				begin
					R1 = close[cnt];
					G2 = close[cnt];
					B3 = WIN2[cnt];
					beep <= 0;
				end
			else if(remain_life!=0 || ball_y!=8'b00000000)
				begin
					// show plat
					if(cnt==plat_1 || cnt==plat_2 || cnt==plat_3) R1[0:7]<=8'b11111110;
					else R1[0:7] = 8'b11111111;
					// show ball
					if (cnt==ball_x) G2<=~ball_y;
					else G2[0:7] = 8'b11111111;
					// show block
					if(block[cnt]==1 && block[cnt+8]==1) B3[0:7] <= 8'b00111111;
					else if(block[cnt]==1 && block[cnt+8]==0) B3[0:7] <= 8'b01111111;
					else if(block[cnt]==0 && block[cnt+8]==0) B3[0:7] <= 8'b11111111;
					else if(block[cnt]==0 && block[cnt+8]==1) B3[0:7] <= 8'b10111111;
				end
			// Lose
			else
				begin
					R1 = LOSE[cnt];
					G2 = close[cnt];
					B3 = close[cnt];
				end
		
			if(start==0)
				begin
					ball_x <= plat_2;
					beep <= 0;
				end			
				
			// restart重新開始
			if(restart==1'b1)
				begin
					cnt = 1;
					plat_pos <= 3'b000;
					ball_y <= 8'b00000010;
					ball_x <= plat_2;
					start <= 0;
					if(stage_1 ==1)	block <= 16'b0100001001011010;
					else	block <= 16'b0101101001000010;
					up <= 1;
					remain_life <= 3;
					beep <= 0;
					score <= 4'b0;
					ten_score = 0;
				end
			
			// Life血量
			if(remain_life==4) life = 4'b1111;
			else if(remain_life==3) life = 4'b1110;
			else if(remain_life==2) life = 4'b1100;
			else if(remain_life==1) life = 4'b1000;
			else life = 4'b0000;
			
			// update status
			plat_1 <= kplat_1 + plat_pos;
			plat_2 <= kplat_2 + plat_pos;
			plat_3 <= kplat_3 + plat_pos;
			
			if(stop==0)
				begin
					// 復活
					if(respawn==1 && last_status_respawn==0 && remain_life!=0)
						begin
							start <= 0;
							ball_x <= plat_2;
							ball_y <= 8'b00000010;
							remain_life <= remain_life - 1;
						end
					// 平台左右移動
					// plat left
					else if(left==0 && last_status_l==1 && plat_pos>0 ) plat_pos <= plat_pos - 1'b1;
					// plat right
					else if(right==0 && last_status_r==1 && plat_pos<5 ) plat_pos <= plat_pos + 1'b1;
					// start game
					else if(start_g==1) start<=1;
					last_status_l <= left;
					last_status_r <= right;	 
					last_status_respawn <= respawn;
					// ball status
					if(start==1 && time_pass == 8'b11111111)
						begin
							beep <= 0;
							// ball raising
							if(up==1)
								begin
									if( ball_x == plat_1 && ball_y == 8'b00000010 )
										begin
											if(plat_pos!=0)	ball_status = 0;				// left
											else	ball_status = 2;
										end
									else if(ball_x == plat_2 && ball_y == 8'b00000010) ball_status = 1;					// centre
									else if( ball_x == plat_3 && ball_y == 8'b00000010 ) 
										begin
											if(plat_pos!=5)	ball_status = 2;				// right
											else	ball_status = 0;
										end							
									if(ball_status==0)
										begin
											if(ball_x == 3'b001 || ball_y == 8'b10000000) ball_status = 2;
											ball_x <= ball_x-1;
											ball_y <= ball_y*2;
										end
									else if(ball_status==1)
										begin
											ball_y <= ball_y*2;
										end
									else if(ball_status==2)
										begin
											if(ball_x==3'b110 || ball_y==8'b10000000) ball_status = 0;
											ball_x <= ball_x+1;
											ball_y <= ball_y*2;
										end
									else if(ball_x==3'b000 && ball_x==plat_1 && ball_y==8'b00000010)
										begin
											ball_x <= ball_x+1;
											ball_y <= ball_y*2;
										end
									else if(ball_x==3'b111 && ball_x==plat_3 && ball_y==8'b00000010)
										begin
											ball_x <= ball_x-1;
											ball_y <= ball_y*2;
										end
								end
							// ball falling
							else 
								begin
									if(ball_status==0)
										begin
											if(ball_x==3'b001) ball_status = 2;
											ball_x <= ball_x-1;
											ball_y <= ball_y/2;
										end
									else if(ball_status==1)
										ball_y <= ball_y/2;
									else if(ball_status==2)
										begin
											if(ball_x==3'b110) ball_status = 0;
											ball_x <= ball_x+1;
											ball_y <= ball_y/2;
										end
								end		
						time_pass <= 8'b0;
						end
				end

			// hit detect
			// 碰球反彈，得分 2nd array
			if(ball_y==8'b01000000 && block[ball_x+8]==1)
				begin
					block[ball_x+8]<=0;
					up <= 0;
					beep <= 1;
					score <= score + 1;
				end
			// 碰球反彈，得分 1st array
			else if(ball_y==8'b10000000 && block[ball_x]==1)
				begin
					block[ball_x]<=0;
					up <= 0;
					beep <= 1;
					score <= score + 1;
				end
			// plat put ball
			else if(ball_y==8'b00000010 && (plat_1==ball_x || plat_2==ball_x || plat_3 == ball_x))
				begin
					up <= 1;
				end
			// ball fall down
			else if(ball_y==8'b10000000)
				begin
					up <= 0;
				end
			
			// 7段顯示器得分的部分
			if(score == 10)
				begin
					ten_score = 1;
					score <= 0;
				end
			d <= score[0];
			c <= score[1];
			b <= score[2];
			a <= score[3];
			
			// score_COM
			score_COM[0] = ~score_COM[0];
			score_COM[1] = ~score_COM[1];
			
			if(score_COM[0])
				begin
					score_led[0] = ~((~b & ~c & ~d)|(a & ~b & ~c)|(~a & b & d)|(~a & c));
					score_led[1] = ~((~a & ~b)|(~b & ~c)|(~a & ~c & ~d)|(~a & c & d));
					score_led[2] = ~((~a & b)|(~b & ~c)|(~a & d));
					score_led[3] = ~((a & ~b & ~c)|(~a & ~b & c)|(~a & c & ~d)|(~a & b & ~c & d)|(~b & ~c & ~d));
					score_led[4] = ~((~b & ~c & ~d)|(~a & c & ~d));
					score_led[5] = ~((~a & b & ~c)|(~a & b & ~d)|(a & ~b & ~c)|(~b & ~c & ~d));
					score_led[6] = ~((a & ~b & ~c )|(~a & ~b & c)|(~a & b & ~c)|(~a & c & ~d));
				end
			else
				begin
					if(ten_score)	score_led = 7'b1001111;
					else	score_led = 7'b0000001;
				end

		if(choose_level==0)	stage_1 <= 1;	
		else stage_1 <= 0;
		end
endmodule

module divfreq(
	input CLK,
	output reg CLK_div
);
	reg [24:0] Count;
	always @(posedge CLK)
		begin
			if(Count > 25000000/1000 )	/* 1Hz = 25000000  10KHz = 2500 */		
				begin
					Count <= 25'b0;
					CLK_div <= ~CLK_div;
				end
			else Count <= Count + 1'b1;
		end
endmodule

module divfreq2(
	input CLK,
	output reg CLK_Hz
);
	reg [24:0] Count;
	always @(posedge CLK)
		begin
			if(Count > 25000000/3000 )	
				begin
					Count <= 25'b0;
					CLK_Hz <= ~CLK_Hz;
				end
			else Count <= Count + 1'b1;
		end
endmodule
