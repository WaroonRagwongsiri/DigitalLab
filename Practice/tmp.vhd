-- (a) write as if/elsif inside a process
y <= "00" when sw = "11" else
	"01" when sw = "10" else
	"11";

process(clk)
begin
	if sw = "11" then
		y <= "00";
	elsif sw = "10" then
		y <= "01";
	else
		y <= "11";
	end if;
end process;

-- (b) write as with/select
process(op)
begin
  case op is
    when "00"   => r <= a;
    when "01"   => r <= b;
    when others => r <= c;
  end case;
end process;

r <= a when op = "00" else
	b when op = "01" else
	c;

-- (c) write as when/else
process(en, d)
begin
  if en = '1' then q <= d;
  else q <= '0';
  end if;
end process;

q <= '1' when en = '1' else '0';