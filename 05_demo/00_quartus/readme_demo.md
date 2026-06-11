# README_DEMO

## Mục đích
File này hướng dẫn cách test demo `da1_demo1` trên kit **DE10-Standard** sau khi đã compile thành công trong Quartus.

---

## 1. Những file cần có

### File để build project
- `da1_demo1.sv`
- `pure_quat_conv2d_3x3_core.sv` và các file RTL liên quan
- `constraint.sdc`
- file pin assignment của DE10-Standard (`.qsf` hoặc import từ CSV)

### File dữ liệu testcase
Trong mỗi lần test, cần có đúng 2 file dữ liệu với **đúng tên**:
- `image_16x16_rgb.hex`
- `kernel_3x3.hex`

Hai file này phải nằm ở vị trí Quartus có thể đọc được lúc compile, thường là:
- cùng thư mục project, hoặc
- cùng thư mục source mà project đang dùng

### File để nạp board
- `da1_demo1.sof`

Nếu muốn lưu vào flash để bật nguồn tự chạy, sau này có thể convert thêm:
- `da1_demo1.jic`

---

## 2. Chuẩn bị testcase

Folder `testcases` đã có các thư mục:
- `testcase1`
- `testcase2`
- `testcase3`
- `testcase4`

Trong mỗi thư mục đều có:
- `image_16x16_rgb.hex`
- `kernel_3x3.hex`
- `README.md`

### Cách dùng
Chọn một testcase, thêm 2 file tương ứng:
- `image_16x16_rgb.hex`
- `kernel_3x3.hex`

vào project để Quartus sẽ đọc khi compile.

Lưu ý:
- Không đổi tên 2 file này
- Mỗi lần đổi testcase thì nên compile lại để nội dung memory được cập nhật vào `.sof`

---

## 3. Kiểm tra project Quartus trước khi compile

### Device
Đảm bảo project đang chọn đúng FPGA của DE10-Standard:
- **Cyclone V**
- **5CSXFC6D6F31C6**

### Constraint
File `constraint.sdc` tối thiểu nên có:
```tcl
create_clock -name CLOCK_50 -period 20.000 [get_ports {CLOCK_50}]
```

### Pin assignment
Cần map đúng các chân:
- `CLOCK_50`
- `KEY[3:0]`
- `SW[9:0]`
- `LEDR[9:0]`
- `HEX0..HEX5`

---

## 4. Compile project

Sau khi chọn testcase và kiểm tra lại file `.hex`, compile project trong Quartus.

Kết quả cần có:
- không còn error syntax
- không còn error SDC
- không còn error pin placement
- sinh ra file `da1_demo1.sof`

Nếu vừa thay testcase mà không compile lại, board sẽ vẫn chạy dữ liệu cũ đã nằm trong `.sof` trước đó.

---

## 5. Nạp code lên DE10-Standard

### Nạp tạm qua JTAG
1. Cắm nguồn cho board
2. Cắm cáp USB-Blaster
3. Mở **Quartus Programmer**
4. Chọn đúng phần cứng USB-Blaster
5. `Auto Detect`
6. Chọn FPGA đúng của board
7. Add file `da1_demo1.sof`
8. Tick `Program/Configure`
9. Bấm `Start`

Sau khi nạp xong, board sẽ chạy demo ngay.

---

## 6. Cách thao tác trên kit

## Ý nghĩa các nút
- `KEY0`: reset
- `KEY1`: start
- `KEY2`: next output
- `KEY3`: previous output

## Ý nghĩa các switch
- `SW[9]`: chọn mode chạy  
  - `0` = **Mode A**: slow debug  
  - `1` = **Mode B**: full-speed 50 MHz

- `SW[8]`: chọn mode hiển thị trên HEX  
  - `0` = hiện **output data**
  - `1` = hiện **output address**

- `SW[3:0]`: chọn lane theo kiểu one-hot  
  - `0001` = lane S
  - `0010` = lane I
  - `0100` = lane J
  - `1000` = lane K

Nếu chọn nhiều hơn 1 switch hoặc không đúng one-hot, lane select bị xem là không hợp lệ.

---

## 7. Ý nghĩa LEDR

## Mode A: slow debug (`SW[9] = 0`)
- `LEDR[0]`: reset done
- `LEDR[1]`: kernel sent/load phase done theo wrapper
- `LEDR[2]`: feeder valid
- `LEDR[3]`: core ready
- `LEDR[4]`: out_valid
- `LEDR[5]`: out_empty
- `LEDR[6]`: feeder active
- `LEDR[7]`: frame_done
- `LEDR[8]`: lane select valid
- `LEDR[9]`: display mode  
  - `0` = output data
  - `1` = output address

## Mode B: full-speed (`SW[9] = 1`)
Các LED debug nhanh sẽ bị tắt:
- `LEDR[0]` đến `LEDR[6]` = 0
- `LEDR[7]`: frame_done
- `LEDR[8]`: lane select valid
- `LEDR[9]`: display mode

---

## 8. Ý nghĩa HEX

Board có 6 LED 7 đoạn:
- `HEX5 .. HEX0`

### Khi `SW[8] = 0`
HEX hiển thị **output data 24-bit** của lane đang chọn:
- `HEX5 = data[23:20]`
- `HEX4 = data[19:16]`
- `HEX3 = data[15:12]`
- `HEX2 = data[11:8]`
- `HEX1 = data[7:4]`
- `HEX0 = data[3:0]`

### Khi `SW[8] = 1`
HEX hiển thị **địa chỉ output** đang đọc.

### Bộ mã hex
7-seg dùng mã:
- `0 1 2 3 4 5 6 7 8 9 A b C d E F`

---

## 9. Trình tự test đề nghị trên kit

## Bước 1: test mode slow debug
1. Gạt `SW[9] = 0`
2. Chọn `SW[8] = 0`
3. Reset bằng `KEY0`
4. Bấm `KEY1` để start
5. Quan sát:
   - LEDR thay đổi chậm
   - sau một thời gian `LEDR[7] = frame_done` sẽ lên
6. Sau khi `frame_done = 1`, chọn lane bằng `SW[3:0]`
7. Dùng:
   - `KEY2` để xem output kế tiếp
   - `KEY3` để quay lại output trước

## Bước 2: test mode full-speed
1. Gạt `SW[9] = 1`
2. Reset bằng `KEY0`
3. Bấm `KEY1` để start
4. Chờ `LEDR[7] = 1`
5. Chọn lane bằng `SW[3:0]`
6. Dùng `KEY2/KEY3` để duyệt output
7. Dùng `SW[8]` để chuyển giữa:
   - xem dữ liệu output
   - xem địa chỉ output

---

## 10. Gợi ý test theo testcase

### Testcase 1
- Ảnh all zero
- Kernel center-only

Kỳ vọng:
- output hầu như hoặc toàn bộ là `000000`

### Testcase 2
- Ảnh constant `010203`
- Kernel center-only

Kỳ vọng:
- nhiều địa chỉ output cho giá trị giống nhau hoặc lặp rất ổn định

### Testcase 3
- Ảnh ramp ngang
- Kernel center-only

Kỳ vọng:
- output tăng dần theo chiều ngang
- dễ kiểm tra thứ tự duyệt output

### Testcase 4
- Một pixel đỏ sáng ở giữa
- Kernel center-only

Kỳ vọng:
- chỉ một vùng rất nhỏ output khác 0
- phần lớn địa chỉ output là 0

---

## 11. Nếu kết quả không đúng thì kiểm tra gì

### Trường hợp `frame_done` không lên
Kiểm tra:
- đã bấm `KEY1` chưa
- `KEY0` có đang giữ reset không
- file `.hex` có được Quartus đọc thành công không
- compile có thực sự sinh `.sof` mới không

### Trường hợp lane không đọc được
Kiểm tra:
- đã đợi `frame_done = 1` chưa
- `SW[3:0]` có đúng one-hot không

### Trường hợp HEX luôn bằng 0
Kiểm tra:
- testcase đang dùng
- `SW[8]` đang ở mode data hay addr
- lane chọn có hợp lệ không
- output của testcase đó có thực sự khác 0 không

### Trường hợp đổi testcase mà kết quả không đổi
Nguyên nhân phổ biến:
- đã copy file `.hex` mới nhưng chưa compile lại project

---

## 12. Khuyến nghị khi demo
Nên bắt đầu bằng:
1. `testcase1`
2. `testcase2`
3. `testcase3`

Vì ba testcase này dễ đoán output hơn và phù hợp để xác nhận:
- nạp dữ liệu từ file
- hoạt động của wrapper
- hoạt động của readback trên kit
