# Testcase 2

## Mục tiêu
Kiểm tra trường hợp ảnh constant, kernel center-only, có expected output chính xác cho từng lane.

## File trong thư mục
- `image_16x16_rgb.hex`
- `kernel_3x3.hex`

## Ngõ vào ảnh
- mọi pixel đều là `010203`
- tức:
  - R = `01`
  - G = `02`
  - B = `03`

## Kernel
- kernel center-only
- chỉ tap giữa `k11 = 000001`
- hiểu là:
  - p = `00`
  - q = `00`
  - s = `01`

## Expected output
Theo công thức trong tap_4lane:

- y0 = -(RP + GQ + BS) = -3
- y1 =  GS - BQ         =  2
- y2 =  BP - RS         = -1
- y3 =  RQ - GP         =  0

Nên tại mọi vị trí output valid:

- lane S = `FFFFFD`
- lane I = `000002`
- lane J = `FFFFFF`
- lane K = `000000`

## Ý nghĩa
Đây là testcase chuẩn để xác nhận:
- đường dữ liệu quaternion đang đúng
- lane select đọc đúng lane
- readback từ RAM output hoạt động đúng
