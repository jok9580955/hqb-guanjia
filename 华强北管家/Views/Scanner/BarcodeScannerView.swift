import SwiftUI
@preconcurrency import AVFoundation
import SwiftData

struct BarcodeScannerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var skuItems: [SKUItem]
    @Query private var locations: [StorageLocation]

    @State private var scannedCode = ""
    @State private var matchedSKU: SKUItem?
    @State private var matchedLocation: StorageLocation?
    @State private var showResult = false
    @State private var isTorchOn = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Camera
                ScannerCameraView(onCodeFound: handleScan, isTorchOn: $isTorchOn)
                    .ignoresSafeArea()

                // Overlay
                VStack {
                    Spacer()

                    // Scan frame
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppTheme.neonGreen, lineWidth: 2)
                        .frame(width: 260, height: 180)
                        .shadow(color: AppTheme.neonGreen.opacity(0.3), radius: 10)
                        .overlay(
                            Text(scannedCode.isEmpty ? "将条码对准框内" : scannedCode)
                                .font(.system(size: 13, weight: .medium, design: .monospaced))
                                .foregroundStyle(AppTheme.neonGreen)
                                .padding(.top, 190)
                        )

                    Spacer()

                    // Controls
                    HStack(spacing: 40) {
                        Button {
                            isTorchOn.toggle()
                            HapticManager.light()
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: isTorchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                                    .font(.system(size: 24))
                                Text("闪光灯").font(.system(size: 11))
                            }
                            .foregroundStyle(isTorchOn ? AppTheme.neonGreen : .white)
                        }

                        Button {
                            scannedCode = ""
                            matchedSKU = nil
                            matchedLocation = nil
                            showResult = false
                            HapticManager.light()
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 24))
                                Text("重新扫码").font(.system(size: 11))
                            }
                            .foregroundStyle(.white)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("扫码")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.black.opacity(0.5), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $showResult) {
                scanResultSheet
            }
        }
    }

    private func handleScan(_ code: String) {
        guard !showResult else { return }
        scannedCode = code
        HapticManager.success()

        matchedSKU = skuItems.first { $0.barcode == code }
        matchedLocation = locations.first { $0.barcode == code }
        showResult = true
    }

    @ViewBuilder
    private var scanResultSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Scanned code
                HStack {
                    Image(systemName: "barcode").foregroundStyle(AppTheme.neonGreen)
                    Text(scannedCode)
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                        .foregroundStyle(AppTheme.textPrimary)
                }
                .padding(14).frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12).fill(AppTheme.cardBackground)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.border, lineWidth: 1))
                )

                if let sku = matchedSKU {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(AppTheme.accentGreen)
                            Text("找到匹配 SKU").font(.system(size: 14, weight: .semibold)).foregroundStyle(AppTheme.accentGreen)
                        }

                        NavigationLink(destination: SKUDetailView(sku: sku)) {
                            HStack {
                                Image(systemName: sku.category?.icon ?? "shippingbox")
                                    .font(.system(size: 20)).foregroundStyle(AppTheme.techBlue)
                                    .frame(width: 40, height: 40)
                                    .background(AppTheme.techBlue.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(sku.name).font(.system(size: 15, weight: .semibold)).foregroundStyle(AppTheme.textPrimary)
                                    Text("库存: \(sku.totalStock)").font(.system(size: 12)).foregroundStyle(AppTheme.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").foregroundStyle(AppTheme.textTertiary)
                            }
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 12).fill(AppTheme.elevatedBackground))
                        }
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14).fill(AppTheme.cardBackground)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.border, lineWidth: 1))
                    )
                } else if let loc = matchedLocation {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "mappin.circle.fill").foregroundStyle(AppTheme.cyan)
                            Text("找到库位: \(loc.fullPath)")
                                .font(.system(size: 14, weight: .semibold)).foregroundStyle(AppTheme.cyan)
                        }
                        Text("该库位有 \(loc.totalQuantity) 件在库")
                            .font(.system(size: 13)).foregroundStyle(AppTheme.textSecondary)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14).fill(AppTheme.cardBackground)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.border, lineWidth: 1))
                    )
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "questionmark.circle").font(.system(size: 36)).foregroundStyle(AppTheme.textTertiary)
                        Text("未找到匹配").font(.system(size: 15, weight: .medium)).foregroundStyle(AppTheme.textSecondary)
                        Text("可用此条码创建新 SKU").font(.system(size: 13)).foregroundStyle(AppTheme.textTertiary)
                    }
                    .padding(20)
                }
                Spacer()
            }
            .padding(16)
            .background(AppTheme.background)
            .navigationTitle("扫码结果")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(AppTheme.secondaryBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Scanner Camera View (UIViewControllerRepresentable)

struct ScannerCameraView: UIViewControllerRepresentable {
    let onCodeFound: (String) -> Void
    @Binding var isTorchOn: Bool

    func makeUIViewController(context: Context) -> ScannerViewController {
        let vc = ScannerViewController()
        vc.onCodeScanned = onCodeFound
        return vc
    }

    func updateUIViewController(_ vc: ScannerViewController, context: Context) {
        vc.updateTorch(isTorchOn)
    }
}

// MARK: - Scanner View Controller

class ScannerViewController: UIViewController {
    var onCodeScanned: ((String) -> Void)?

    private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let metadataOutput = AVCaptureMetadataOutput()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        checkCameraPermission()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    Task { @MainActor in self.setupCamera() }
                }
            }
        default:
            break
        }
    }

    private func setupCamera() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else { return }

        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }

        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
            metadataOutput.metadataObjectTypes = [.ean8, .ean13, .code128, .code39, .qr, .dataMatrix, .upce]
        }

        let layer = AVCaptureVideoPreviewLayer(session: captureSession)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.bounds
        view.layer.addSublayer(layer)
        previewLayer = layer

        let session = captureSession
        Task.detached { session.startRunning() }
    }

    func updateTorch(_ on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        try? device.lockForConfiguration()
        device.torchMode = on ? .on : .off
        device.unlockForConfiguration()
    }
}

extension ScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    // Delegate is set with queue: .main, so this is called on main thread
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let value = obj.stringValue else { return }
        onCodeScanned?(value)
    }
}
