# Testcase 1

## Mục tiêu
Kiểm tra đường dữ liệu cơ bản khi ảnh vào toàn 0.

## File trong thư mục
- `image_16x16_rgb.hex`
- `kernel_3x3.hex`

## Ngõ vào ảnh
- 16x16 pixel
- mọi pixel đều là `000000`

## Kernel
- kernel center-only
- chỉ tap giữa `k11 = 000001`
- các tap còn lại = `000000`

## Expected output
Vì mọi pixel đầu vào đều bằng 0 nên với mọi vị trí output valid:

- lane S = `000000`
- lane I = `000000`
- lane J = `000000`
- lane K = `000000`

## Ý nghĩa
Đây là testcase sạch nhất để kiểm tra:
- nạp file HEX
- chạy đủ frame
- đọc lại output
- không có dữ liệu rác
