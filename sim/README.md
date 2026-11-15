# Metro Card Accelerator IP — Hướng Dẫn Chạy Mô Phỏng Cadence Xcelium & Tạo Ảnh Báo Cáo LaTeX

Tài liệu này hướng dẫn chi tiết cách thiết lập môi trường **Cadence Xcelium (`xrun`, `imc`, `simvision`)**, chạy từng testcase, chạy regression, tính toán thông số AI (`metrics`), gộp và xuất báo cáo Coverage (`cov_merge`, `cov_summary`, `cov_gui`), mở waveform (`make wave`), và **hướng dẫn từng bước để chụp lại toàn bộ bộ ảnh mô phỏng** thay thế vào thư mục `img/` của báo cáo LaTeX.

---

## 1. Cấu Trúc Thư Mục Dự Án

Toàn bộ mã nguồn trong các thư mục `rtl/`, `tb/`, `testcases/`, `sequences/`, `vip/` được giữ nguyên 100%. Chỉ môi trường mô phỏng trong `sim/` và file danh sách `vip/vip.f` được cấu hình cho **Cadence Xcelium**:

```text
Metro-Card-Accelerator-v2-main/
├── docs/
│   └── TESTPLAN.md                # Kế hoạch kiểm thử (Verification Plan)
├── metrics/
│   ├── ai_metrics.py              # Script tính toán Confusion Matrix & chỉ số phân loại AI
│   └── example_labels.csv
├── rtl/                           # Mã nguồn RTL của IP (giữ nguyên 100%)
│   ├── apb_slave.sv
│   ├── fallback_lookup.sv
│   ├── hash_engine.sv
│   ├── metro_card_top.sv
│   ├── register.sv
│   └── sram.sv
├── vip/                           # APB Verification IP (giữ nguyên 100% code)
│   ├── vip.f                      # File list cho VIP
│   ├── metro_apb_if.sv
│   ├── metro_apb_pkg.sv
│   ├── metro_apb_transaction.sv
│   ├── metro_apb_sequencer.sv
│   ├── metro_apb_driver.sv
│   ├── metro_apb_monitor.sv
│   └── metro_apb_agent.sv
├── tb/                            # UVM Environment, Scoreboard & Testbench top (giữ nguyên 100%)
│   ├── env_pkg.sv
│   ├── metro_scoreboard.sv
│   ├── metro_environment.sv
│   └── testbench.sv
├── sequences/                     # Các UVM Sequence (giữ nguyên 100%)
│   ├── seq_pkg.sv
│   ├── metro_sequences.sv
│   └── metro_fallback_auto_clear_sequence.sv
├── testcases/                     # 9 UVM Testcases + Base Test (giữ nguyên 100%)
│   ├── test_pkg.sv
│   ├── metro_base_test.sv
│   ├── metro_reset_test.sv
│   ├── metro_register_test.sv
│   ├── metro_hash_program_test.sv
│   ├── metro_smoke_test.sv
│   ├── metro_fallback_miss_test.sv
│   ├── metro_fallback_table_test.sv
│   ├── metro_fallback_auto_clear_test.sv
│   ├── metro_metrics_test.sv
│   └── metro_coverage_closure_test.sv
└── sim/                           # Môi trường chạy mô phỏng Cadence Xcelium
    ├── Makefile                   # Makefile sử dụng xrun, imc, simvision
    ├── project_env.bash           # Script thiết lập biến môi trường
    ├── rtl.f                      # File list RTL
    ├── tb.f                       # File list Testbench & UVM packages
    ├── cov.ccf                    # Cấu hình Code Coverage (RTL) & Functional Coverage (UVM)
    ├── simvision_dut.tcl          # Script tự động nạp 26 tín hiệu DUT vào SimVision
    ├── regress.cfg                # Cấu hình danh sách 9 testcases cho regression
    └── regress.pl                 # Script chạy regression và xuất regress.rpt
```

---

## 2. Thiết Lập Môi Trường (`sim/`)

Mở terminal trên máy chủ Linux có cài đặt bộ công cụ Cadence (**Xcelium `xrun`**, **Integrated Metrics Center `imc`**, **SimVision `simvision`**):

```bash
cd sim
source project_env.bash
```

> **Lưu ý**: Mặc định `Makefile` sử dụng thư viện UVM 1.2 tích hợp sẵn của Cadence Xcelium (`UVM_HOME=CDNS-1.2`). Nếu hệ thống của bạn dùng đường dẫn UVM riêng, có thể truyền `UVM_HOME=/duong/dan/uvm-1.2`.

Để dọn sạch dữ liệu cũ trước khi chạy mới:

```bash
make clean
```

---

## 3. Hướng Dẫn Chạy Từng Lệnh Trong `Makefile`

### 3.1. Chạy từng Testcase riêng lẻ (9 Testcases)

Sử dụng lệnh `make all TESTNAME=<tên_test> SEED=1` (hoặc thêm `COV=ON` nếu muốn thu thập cả Code Coverage và Functional Coverage cho testcase đó):

```bash
# 1. Testcase kiểm tra Reset và trạng thái khởi tạo
make all TESTNAME=metro_reset_test SEED=1 COV=ON

# 2. Testcase kiểm tra đọc/ghi thanh ghi APB (ID_REG, CTRL_REG)
make all TESTNAME=metro_register_test SEED=1 COV=ON

# 3. Testcase kiểm tra Hash Engine, Bloom Program/Query và Auto-clear cơ bản
make all TESTNAME=metro_hash_program_test SEED=1 COV=ON

# 4. Testcase kiểm tra tổng hợp (Smoke Test)
make all TESTNAME=metro_smoke_test SEED=1 COV=ON

# 5. Testcase kiểm tra phát hiện qua Fallback và trường hợp Miss
make all TESTNAME=metro_fallback_miss_test SEED=1 COV=ON

# 6. Testcase kiểm tra đọc/ghi/ghi đè/xóa trên 16 slot của bảng Fallback
make all TESTNAME=metro_fallback_table_test SEED=1 COV=ON

# 7. Testcase kiểm tra tự động xóa (Auto-Clear) Fallback sau khi Program Bloom
make all TESTNAME=metro_fallback_auto_clear_test SEED=1 COV=ON

# 8. Testcase đánh giá tập dữ liệu phân loại 1.280 mẫu (xuất file CSV cho AI metrics)
make all TESTNAME=metro_metrics_test SEED=1 COV=ON

# 9. Testcase đóng kín 100% Code Coverage & Functional Coverage
make all TESTNAME=metro_coverage_closure_test SEED=1 COV=ON
```

Sau khi mỗi testcase chạy xong:
- File log mô phỏng nằm tại: `log/<TESTNAME>_<SEED>.log` (và symlink `log/run.log`).
- Cơ sở dữ liệu waveform (SHM) nằm tại: `log/<TESTNAME>_<SEED>.shm`.
- Cơ sở dữ liệu coverage (nếu `COV=ON`) nằm tại: `log/cov_work/scope/<TESTNAME>_<SEED>`.

---

### 3.2. Chạy toàn bộ Regression (`regress`)

Chạy tự động cả 9 testcases với `COV=ON` (theo cấu hình trong `regress.cfg`) và tạo bảng tổng hợp `regress.rpt`:

```bash
make clean
./regress.pl
# hoặc:
make regress
```

Xem kết quả báo cáo regression trên terminal:

```bash
cat regress.rpt
```

---

### 3.3. Tính toán thông số AI / Classification Metrics (`metrics`)

Sau khi đã chạy `metro_metrics_test` (hoặc sau khi chạy `./regress.pl`), file `log/metro_metrics_results.csv` (gồm 1.280 mẫu kiểm thử) sẽ được sinh ra. Chạy lệnh sau để tính Confusion Matrix (`TP`, `FP`, `TN`, `FN`) và các thông số `Accuracy`, `Precision`, `Recall`, `Specificity`, `F1 Score`, `FPR`, `FNR`:

```bash
make metrics
# hoặc chạy trực tiếp:
python3 ../metrics/ai_metrics.py log/metro_metrics_results.csv
```

---

### 3.4. Gộp Coverage & Xem Báo Cáo Coverage (`cov_merge`, `cov_summary`, `cov_report`, `cov_gui`)

Sau khi chạy các testcase với `COV=ON` (ví dụ sau khi chạy `./regress.pl`):

1. **Gộp toàn bộ coverage của 9 testcases vào `IP_MERGE` (`cov_merge`)**:
   ```bash
   make cov_merge
   ```
   Lệnh này dùng công cụ **Cadence IMC (`imc`)** để gộp tất cả các thư mục coverage trong `log/cov_work/scope/*` thành `log/cov_work/scope/IP_MERGE`, đồng thời xuất ra:
   - `log/IP_MERGE_coverage_summary.txt` (Báo cáo tổng hợp)
   - `log/IP_MERGE_coverage_details.txt` (Báo cáo chi tiết từng module RTL & từng covergroup)

2. **In nhanh bảng tổng hợp Coverage ra màn hình terminal (`cov_summary`)**:
   ```bash
   make cov_summary
   ```

3. **Xuất báo cáo chi tiết cho 1 testcase cụ thể (`cov_report`)**:
   ```bash
   make cov_report TESTNAME=metro_hash_program_test
   ```

4. **Mở giao diện đồ họa Cadence IMC GUI (`cov_gui`)**:
   - Mở database tổng hợp `IP_MERGE` (để chụp ảnh Functional Coverage & Code Coverage):
     ```bash
     make cov_gui TESTNAME=IP_MERGE
     ```
   - Mở database của 1 testcase riêng lẻ:
     ```bash
     make cov_gui TESTNAME=metro_hash_program_test
     ```

---

### 3.5. Mở Waveform bằng Cadence SimVision (`make wave`)

Để mở cửa sổ dạng sóng **SimVision** cho bất kỳ testcase nào đã chạy (tự động nạp sẵn 26 tín hiệu chuẩn của `testbench.dut` qua `simvision_dut.tcl`):

```bash
make wave TESTNAME=metro_register_test
# hoặc chỉ định rõ SEED nếu có nhiều lần chạy:
make wave TESTNAME=metro_register_test SEED=1
```

> **Mẹo trong SimVision**:
> - Nếu muốn nạp lại 26 tín hiệu theo đúng thứ tự trong báo cáo LaTeX: trên thanh menu SimVision chọn **File → Source Command Script...** → chọn `simvision_dut.tcl`.
> - Để đổi hệ cơ số (Radix) của các bus (`PADDR`, `PWDATA`, `PRDATA`, `id_data`, `programmed_id`, `fallback_rdata`, `index1..4`): bôi đen các tín hiệu → chuột phải → **Radix** → chọn **Hexadecimal** hoặc **Unsigned Decimal** tùy theo từng ảnh bên dưới.

---

## 4. Hướng Dẫn Chi Tiết Tạo & Chụp Lại Toàn Bộ Ảnh Mô Phỏng Cho Báo Cáo LaTeX

Trong file báo cáo LaTeX (`VM3_SV039___Báo_cáo_Vòng_Hoàn_thiện_Sản_phẩm/main.tex`), các ảnh mô phỏng, kết quả kiểm chứng, thông số AI và coverage nằm trong thư mục `img/`.

Quy trình chuẩn bị nhanh nhất trước khi chụp ảnh:

```bash
cd sim
source project_env.bash
make clean
./regress.pl
make cov_merge
```

Sau khi chạy xong 4 lệnh trên, **toàn bộ 9 file log, 9 database waveform `.shm`, file `metro_metrics_results.csv`, file `regress.rpt` và database coverage gộp `IP_MERGE` đều đã sẵn sàng**. Bạn chỉ cần làm theo bảng hướng dẫn dưới đây để chụp từng ảnh và lưu đè vào thư mục `img/` của báo cáo LaTeX.

---

### PHẦN A: Các Ảnh Tổng Hợp Regression, Coverage & Thông Số AI (`shot1.png` – `shot4.png`)

| Tên file ảnh trong `img/` | Vị trí trong `main.tex` | Nội dung ảnh cần chụp | Lệnh chạy & Cách chụp ảnh thay thế |
| :--- | :--- | :--- | :--- |
| **`img/shot1.png`** | Mục 6.14 (`\label{fig:reg}`)<br>*Metro Card Regression Report: 9 log đều Passed* | Màn hình terminal hiển thị nội dung file `regress.rpt` với `Log files classified: 9`, `Passed: 9`, `Failed: 0`, `Unknown: 0` và danh sách 9 file `log/metro_*_test_<seed>.log : Passed`. | Chạy trên terminal:<br>`cat regress.rpt`<br>Chụp màn hình khung terminal từ dòng `##### Metro Card Regression Report #####` đến dòng cuối `Note: only simulation logs...`. |
| **`img/shot2.png`** | Mục 6.15 (`\label{fig:cov}`)<br>*Báo cáo coverage: code coverage và functional coverage* | Màn hình terminal (hoặc cửa sổ IMC Summary) hiển thị bảng tổng hợp Code Coverage (Block/Statement, Branch, Expression, Toggle đạt 100% trên RTL `metro_card_top`) và Functional Coverage (Covergroup đạt 100%). | Chạy trên terminal:<br>`make cov_summary`<br>*(hoặc `cat log/IP_MERGE_coverage_summary.txt`)*<br>Chụp màn hình bảng tổng hợp Coverage in ra trên terminal (hoặc chụp tab **Summary** trong `make cov_gui TESTNAME=IP_MERGE`). |
| **`img/shot3.png`** | Mục 6.16 (`\label{fig:metrics}`)<br>*Kết quả chạy `ai_metrics.py` trên `log/metro_metrics_results.csv`* | Màn hình terminal hiển thị kết quả chạy thông số AI: `Samples: 1280`, `TP / FP: 256 / 3`, `TN / FN: 1021 / 0`, `Accuracy: 99.77%`, `Precision: 98.84%`, `Recall: 100.00%`, `Specificity: 99.71%`, `F1 Score: 0.9942`, `FPR: 0.29%`, `FNR: 0.00%` và bảng `Confusion Matrix`. | Chạy trên terminal:<br>`python3 ../metrics/ai_metrics.py log/metro_metrics_results.csv`<br>*(hoặc `make metrics`)*<br>Chụp màn hình terminal từ dòng lệnh `python3 ...` đến hết bảng Confusion Matrix. |
| **`img/shot4.png`** | Mục 6.15 (`\label{fig:cvg}`)<br>*Cửa sổ Covergroups* | Cửa sổ giao diện đồ họa Coverage hiển thị cây **Covergroups** trong `env_pkg -> metro_scoreboard` gồm 4 covergroup (`operation_mode_cg`, `fallback_slot_action_cg`, `query_result_cg`, `idle_status_cg`) và toàn bộ 12 coverpoint/cross mở rộng bên dưới đều đạt **100%** (thanh màu xanh lá). | Chạy lệnh mở IMC GUI:<br>`make cov_gui TESTNAME=IP_MERGE`<br>Trong cửa sổ **Cadence IMC**, chọn chế độ xem **Verification / Covergroups**, mở rộng nhánh `env_pkg` → `metro_scoreboard` để hiện đầy đủ 4 covergroup và các coverpoint bên trong cùng cột `100%` màu xanh, sau đó chụp ảnh vùng cửa sổ này. |

---

### PHẦN B: Các Ảnh Log & Waveform Của Từng Testcase (`shot5.png` – `shot8.png`, `tc3_*` – `tc8_*`)

> **Danh sách 26 tín hiệu chuẩn trên mọi ảnh Waveform** (đã được nạp tự động theo đúng thứ tự khi chạy `make wave TESTNAME=...`):
> 1. `PCLK`, 2. `PRESETN`, 3. `PSEL`, 4. `PWRITE`, 5. `PENABLE`, 6. `PADDR`, 7. `PWDATA`, 8. `PRDATA`, 9. `PREADY`,
> 10. `id_data`, 11. `start`, 12. `mode`, 13. `match`, 14. `fallback_hit`, 15. `fallback_match`, 16. `done`, 17. `program_done`, 18. `clear_done`, 19. `programmed_id`, 20. `fallback_rdata`,
> 21. `index1`, 22. `index2`, 23. `index3`, 24. `index4`, 25. `wr_en`, 26. `rd_en`.

| Testcase | Tên file ảnh trong `img/` | Trạng thái trong `main.tex` | Nội dung & Thông số hiển thị cần khớp với báo cáo | Lệnh chạy & Cách chụp ảnh mới |
| :--- | :--- | :--- | :--- | :--- |
| **TC1**<br>`metro_register_test`<br>*(Mục 6.5)* | **`img/shot5.png`** | **Đang hiển thị** (`\label{fig:tc1log}`) | Log mô phỏng `metro_register_test`: hiển thị bảng `UVM_INFO` Topology (`uvm_test_top -> env -> apb_agent / scoreboard`), dòng `Scoreboard: operations=0 status_checks=0 fallback_hits=0 BIT_COUNT=4096`, `#### TEST PASSED ####`, UVM Report Summary (`UVM_INFO : 8`, `UVM_ERROR : 0`), kết thúc tại `170 ns`. | Chạy:<br>`cat log/metro_register_test_*.log`<br>Chụp màn hình phần từ bảng UVM Topology đến hết UVM Report Summary. |
| **TC1**<br>`metro_register_test`<br>*(Mục 6.5)* | **`img/shot6.png`** | Lưu trong `img/` *(ẩn trong `.tex` để tiết kiệm trang)* | Waveform `metro_register_test` trong khoảng **`0 ns – 170 ns`**, Radix: **Hexadecimal**. Thể hiện `PRESETN` lên 1 ở `35 ns`, ghi `0x13572468` vào `PADDR=0x00` (`60–80 ns`), đọc lại `0x00` (`90–110 ns`), ghi `0x02` vào `PADDR=0x04` (`120–140 ns`), đọc lại `0x04` (`150–170 ns`). | Chạy:<br>`make wave TESTNAME=metro_register_test`<br>Trong SimVision: chọn Radix **Hexadecimal**, zoom toàn bộ khoảng **`0 ns – 170 ns`** và chụp cửa sổ waveform. |
| **TC2**<br>`metro_hash_program_test`<br>*(Mục 6.6)* | **`img/shot7.png`** | **Đang hiển thị** (`\label{fig:tc2log}`) | Log mô phỏng `metro_hash_program_test`: hiển thị 15 dòng `[metro_scoreboard] PASS ID=...` và 7 dòng `[metro_hash_sequence] QUERY PASS`, dòng `operations=15 status_checks=15 fallback_hits=0 BIT_COUNT=4096`, `#### TEST PASSED ####`, kết thúc tại `1670 ns`. | Chạy:<br>`tail -n 45 log/metro_hash_program_test_*.log`<br>Chụp màn hình từ dòng PASS đầu tiên (`225 ns`) đến hết phần UVM Report Summary. |
| **TC2**<br>`metro_hash_program_test`<br>*(Mục 6.6)* | **`img/shot8.png`** | **Đang hiển thị** (`\label{fig:tc2wave}`) | Waveform `metro_hash_program_test` zoom vào khoảng **`50 ns – 350 ns`** (lần Program đầu tiên): nạp trước 3 slot Fallback (`60–150 ns`), ghi `ID_REG = 0xFFFFFFFF` (`150–170 ns`, `fallback_hit=1`), ghi `CTRL_REG = 3` (`180–200 ns`), xung `program_done` và `fallback_hit` tự xóa về `0` tại `215 ns`, đọc `STAT_REG=1` và đọc lại 3 slot (`240–320 ns`). | Chạy:<br>`make wave TESTNAME=metro_hash_program_test`<br>Trong SimVision: zoom trục thời gian vào đoạn **`50 ns – 350 ns`** (Radix: **Unsigned Decimal** hoặc **Hexadecimal**) và chụp cửa sổ waveform. |
| **TC3**<br>`metro_reset_test`<br>*(Mục 6.7)* | **`img/tc3_log.png`** | Lưu trong `img/` | Log mô phỏng `metro_reset_test`: hiển thị UVM Topology, `operations=0 status_checks=0 fallback_hits=0`, `idle_status=100.00%`, `#### TEST PASSED ####`, kết thúc tại `80 ns`. | Chạy:<br>`cat log/metro_reset_test_*.log`<br>Chụp màn hình log từ UVM Topology đến hết UVM Report Summary. |
| **TC3**<br>`metro_reset_test`<br>*(Mục 6.7)* | **`img/tc3_wave.png`** | Lưu trong `img/` | Waveform `metro_reset_test` trong khoảng **`0 ns – 80 ns`**, Radix: **Hexadecimal**. Thể hiện `PRESETN=0` (`0–35 ns`), `PRESETN=1` (`35 ns`), đọc `STAT_REG` (`PADDR=0x08`) tại `60–80 ns` trả về `PRDATA=0x00000000`. | Chạy:<br>`make wave TESTNAME=metro_reset_test`<br>Trong SimVision: chọn Radix **Hexadecimal**, zoom khoảng **`0 ns – 80 ns`** và chụp ảnh. |
| **TC4**<br>`metro_smoke_test`<br>*(Mục 6.8)* | **`img/tc4_log.png`** | Lưu trong `img/` | Log mô phỏng `metro_smoke_test`: hiển thị 18 lần kiểm tra PASS (`operations=18 status_checks=18 fallback_hits=1`), `#### TEST PASSED ####`, kết thúc tại `2030 ns`. | Chạy:<br>`tail -n 48 log/metro_smoke_test_*.log`<br>Chụp màn hình các dòng PASS và UVM Report Summary. |
| **TC4**<br>`metro_smoke_test`<br>*(Mục 6.8)* | **`img/tc4_wave.png`** | Lưu trong `img/` | Waveform `metro_smoke_test` zoom vào khoảng **`45 ns – 300 ns`**: ghi `0xD00DCAFE` vào slot 0 (`60–80 ns`), ghi `ID_REG` (`90–110 ns`, `fallback_hit=1`), Query (`120–145 ns`, `done=1, match=1, fallback_match=1`), đọc `STAT_REG=7` (`150–170 ns`), đọc lại slot 0 (`180–200 ns`), xóa slot 0 về 0 (`210–230 ns`). | Chạy:<br>`make wave TESTNAME=metro_smoke_test`<br>Trong SimVision: zoom khoảng **`45 ns – 300 ns`** và chụp ảnh. |
| **TC5**<br>`metro_metrics_test`<br>*(Mục 6.9)* | **`img/tc5_log.png`** | **Đang hiển thị** (`\label{fig:tc5log}`) | Đoạn cuối log mô phỏng `metro_metrics_test`: hiển thị các dòng PASS cuối của clean ID (`0x700003db` .. `0x700003fc`), dòng `Wrote 1280 observed samples to log/metro_metrics_results.csv; predicted_black=259`, `operations=1520 status_checks=1520 fallback_hits=16`, `#### TEST PASSED ####`, kết thúc tại `137330 ns`. | Chạy:<br>`tail -n 45 log/metro_metrics_test_*.log`<br>Chụp màn hình đoạn cuối của log có chứa dòng `Wrote 1280 observed samples...` và `#### TEST PASSED ####`. |
| **TC5**<br>`metro_metrics_test`<br>*(Mục 6.9)* | **`img/tc5_wave.png`** | Lưu trong `img/` | Waveform `metro_metrics_test` zoom vào khoảng **`40 ns – 385 ns`**: 4 chu trình Program đầu tiên (`0x10000000` .. `0x10000003`), mỗi chu trình cách nhau `90 ns`. | Chạy:<br>`make wave TESTNAME=metro_metrics_test`<br>Trong SimVision: zoom khoảng **`40 ns – 385 ns`** và chụp ảnh. |
| **TC6**<br>`metro_fallback_table_test`<br>*(Mục 6.10)* | **`img/tc6_log.png`** | Lưu trong `img/` | Log mô phỏng `metro_fallback_table_test`: hiển thị 5 lần kiểm tra PASS (`0xabcd0001`, `0xabcd00f2`, `0xabcd0010`), `operations=5 status_checks=5 fallback_hits=2`, `fallback_slot_action=100.00%`, `#### TEST PASSED ####`, kết thúc tại `830 ns`. | Chạy:<br>`cat log/metro_fallback_table_test_*.log`<br>Chụp màn hình phần kết quả PASS và UVM Report Summary. |
| **TC6**<br>`metro_fallback_table_test`<br>*(Mục 6.10)* | **`img/tc6_wave.png`** | Lưu trong `img/` | Waveform `metro_fallback_table_test` zoom vào khoảng **`40 ns – 285 ns`**: ghi slot 0 (`PADDR=16`), slot 1 (`PADDR=20`), slot 15 (`PADDR=76`) từ `60–140 ns`, đọc lại 3 slot (`150–230 ns`), và ghi đè slot 1 (`240–260 ns`). | Chạy:<br>`make wave TESTNAME=metro_fallback_table_test`<br>Trong SimVision: zoom khoảng **`40 ns – 285 ns`** và chụp ảnh. |
| **TC7**<br>`metro_fallback_miss_test`<br>*(Mục 6.11)* | **`img/tc7_log.png`** | Lưu trong `img/` | Log mô phỏng `metro_fallback_miss_test`: hiển thị 3 lần kiểm tra PASS (`0xd00dcafe` hit `0x7`, `0xd00dcafe` sau xóa `0x1`, `0xcafebabe` miss `0x1`), `operations=3 status_checks=3 fallback_hits=1`, `#### TEST PASSED ####`, kết thúc tại `410 ns`. | Chạy:<br>`cat log/metro_fallback_miss_test_*.log`<br>Chụp màn hình kết quả PASS và UVM Report Summary. |
| **TC7**<br>`metro_fallback_miss_test`<br>*(Mục 6.11)* | **`img/tc7_wave.png`** | Lưu trong `img/` | Waveform `metro_fallback_miss_test` zoom vào khoảng **`45 ns – 295 ns`**: ghi `0xD00DCAFE` vào slot 0 (`60–80 ns`), Query hit (`120–145 ns`), đọc `STAT_REG=7` và đọc lại slot 0 (`150–200 ns`), ghi `0` xóa slot 0 (`220–230 ns`, `fallback_hit` về `0`). | Chạy:<br>`make wave TESTNAME=metro_fallback_miss_test`<br>Trong SimVision: zoom khoảng **`45 ns – 295 ns`** và chụp ảnh. |
| **TC8**<br>`metro_fallback_auto_clear_test`<br>*(Mục 6.12)* | **`img/tc8_log.png`** | **Đang hiển thị** (`\label{fig:tc8log}`) | Log mô phỏng `metro_fallback_auto_clear_test`: hiển thị các bản tin `AUTO-CLEAR: insert committed ID twice...`, `AUTO-CLEAR: program ID=0xc1ea0001 into Bloom`, `AUTO-CLEAR TEST COMPLETED`, 5 dòng PASS của scoreboard, `operations=5 status_checks=5 fallback_hits=3`, `#### TEST PASSED ####`, kết thúc tại `770 ns`. | Chạy:<br>`cat log/metro_fallback_auto_clear_test_*.log`<br>Chụp màn hình từ dòng `AUTO-CLEAR: insert committed ID twice...` đến hết phần UVM Report Summary. |
| **TC8**<br>`metro_fallback_auto_clear_test`<br>*(Mục 6.12)* | **`img/tc8_wave.png`** | **Đang hiển thị** (`\label{fig:tc8wave}`) | Waveform `metro_fallback_auto_clear_test` zoom vào khoảng **`45 ns – 330 ns`**: 3 lần ghi Fallback (`60–140 ns`: slot 0 = `0xC1EA0001`, slot 1 = `0x51DE0002`, slot 2 = `0xC1EA0001`), đọc lại 3 slot (`150–230 ns`), ghi `ID_REG = 0xC1EA0001` (`240–260 ns`, `fallback_hit=1`), Query (`270–295 ns`, `done=1, match=1, fallback_match=1`), đọc `STAT_REG=7` (`310–320 ns`). | Chạy:<br>`make wave TESTNAME=metro_fallback_auto_clear_test`<br>Trong SimVision: zoom khoảng **`45 ns – 330 ns`** và chụp ảnh. |

---

## 5. Tổng Kết Nhanh 10 Ảnh Đang Hiển Thị Trực Tiếp Trong PDF Báo Cáo LaTeX (`main.tex`)

Nếu bạn chỉ cần thay thế **10 bức ảnh mô phỏng đang được `\includegraphics` trực tiếp trong `main.tex`** (các ảnh còn lại đã được tác giả báo cáo comment `%` để giữ giới hạn 40 trang), bạn chỉ cần chụp đúng 10 file sau và chép đè vào `VM3_SV039___Báo_cáo_Vòng_Hoàn_thiện_Sản_phẩm/img/`:

1. **`img/shot1.png`** — Kết quả `cat regress.rpt` (9/9 testcases Passed).
2. **`img/shot2.png`** — Kết quả `make cov_summary` / `cat log/IP_MERGE_coverage_summary.txt` (Code & Functional Coverage Summary).
3. **`img/shot3.png`** — Kết quả `make metrics` (`python3 ../metrics/ai_metrics.py log/metro_metrics_results.csv`).
4. **`img/shot4.png`** — Cửa sổ Covergroups trong IMC GUI (`make cov_gui TESTNAME=IP_MERGE`).
5. **`img/shot5.png`** — Log của `metro_register_test` (`cat log/metro_register_test_*.log`).
6. **`img/shot7.png`** — Log của `metro_hash_program_test` (`tail -n 45 log/metro_hash_program_test_*.log`).
7. **`img/shot8.png`** — Waveform của `metro_hash_program_test` đoạn `50 – 350 ns` (`make wave TESTNAME=metro_hash_program_test`).
8. **`img/tc5_log.png`** — Đoạn cuối log của `metro_metrics_test` (`tail -n 45 log/metro_metrics_test_*.log`).
9. **`img/tc8_log.png`** — Log của `metro_fallback_auto_clear_test` (`cat log/metro_fallback_auto_clear_test_*.log`).
10. **`img/tc8_wave.png`** — Waveform của `metro_fallback_auto_clear_test` đoạn `45 – 330 ns` (`make wave TESTNAME=metro_fallback_auto_clear_test`).
