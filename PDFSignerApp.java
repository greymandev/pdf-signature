import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.ArrayList;
import java.util.List;
import javax.swing.*;
import javax.swing.filechooser.FileNameExtensionFilter;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;

/**
 * PDFSignerApp - A Java application for automating PDF signing with AutoFirma
 */
public class PDFSignerApp {
    // Default values
    private static final String DEFAULT_LOCATION = "Madrid";
    private static final String DEFAULT_REASON = "Document validation";
    private static final boolean DEFAULT_VISIBLE = false;
    private static final boolean DEFAULT_TIMESTAMP = false;
    
    // Signature position and appearance
    private static final int SIG_X = 50;
    private static final int SIG_Y = 50;
    private static final int SIG_WIDTH = 200;
    private static final int SIG_HEIGHT = 100;
    private static final int SIG_PAGE = 1;
    private static final int SIG_FONT_SIZE = 9;
    private static final String SIG_FONT_COLOR = "black";
    private static final String SIG_TEXT = "Firmado por [NAME] el día [DATE] Certificado [ISSUER]";

    /**
     * Main entry point for the application
     * @param args Command line arguments
     */
    public static void main(String[] args) {
        if (args.length == 0) {
            // GUI mode
            SwingUtilities.invokeLater(() -> {
                try {
                    UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
                } catch (Exception e) {
                    logError("Failed to set system look and feel: " + e.getMessage());
                }
                showGUI();
            });
        } else {
            // Command line mode
            try {
                String[] params = parseArgs(args);
                if (params != null) {
                    String inputDir = params[0];
                    String outputDir = params[1];
                    String certPath = params[2];
                    String password = params[3];
                    String location = params[4];
                    String reason = params[5];
                    boolean visible = Boolean.parseBoolean(params[6]);
                    boolean timestamp = Boolean.parseBoolean(params[7]);
                    
                    processPDFs(inputDir, outputDir, certPath, password, location, reason, visible, timestamp);
                }
            } catch (Exception e) {
                logError("Error: " + e.getMessage());
                showUsage();
            }
        }
    }

    private static String[] parseArgs(String[] args) {
        String inputDir = null;
        String outputDir = null;
        String certPath = null;
        String password = null;
        String location = DEFAULT_LOCATION;
        String reason = DEFAULT_REASON;
        boolean visible = DEFAULT_VISIBLE;
        boolean timestamp = DEFAULT_TIMESTAMP;

        for (int i = 0; i < args.length; i++) {
            switch (args[i]) {
                case "-i":
                case "--input-dir":
                    if (i + 1 < args.length) inputDir = args[++i];
                    break;
                case "-o":
                case "--output-dir":
                    if (i + 1 < args.length) outputDir = args[++i];
                    break;
                case "-c":
                case "--cert":
                    if (i + 1 < args.length) certPath = args[++i];
                    break;
                case "-p":
                case "--password":
                    if (i + 1 < args.length) password = args[++i];
                    break;
                case "-l":
                case "--location":
                    if (i + 1 < args.length) location = args[++i];
                    break;
                case "-r":
                case "--reason":
                    if (i + 1 < args.length) reason = args[++i];
                    break;
                case "-v":
                case "--visible":
                    visible = true;
                    break;
                case "-t":
                case "--timestamp":
                    timestamp = true;
                    break;
                case "-h":
                case "--help":
                    showUsage();
                    return null;
                default:
                    throw new IllegalArgumentException("Unknown option: " + args[i]);
            }
        }

        // Validate required parameters
        if (inputDir == null || outputDir == null || certPath == null || password == null) {
            throw new IllegalArgumentException("Missing required parameters");
        }

        // Validate paths
        validatePath(inputDir, true, true);
        validatePath(outputDir, false, true);
        validatePath(certPath, true, false);

        return new String[]{inputDir, outputDir, certPath, password, location, reason, String.valueOf(visible), String.valueOf(timestamp)};
    }

    private static void validatePath(String pathStr, boolean mustExist, boolean isDirectory) {
        Path path = Paths.get(pathStr);
        
        if (mustExist && !Files.exists(path)) {
            throw new IllegalArgumentException("Path does not exist: " + pathStr);
        }
        
        if (isDirectory && Files.exists(path) && !Files.isDirectory(path)) {
            throw new IllegalArgumentException("Path is not a directory: " + pathStr);
        }
    }

    private static void showUsage() {
        System.out.println("Usage: java PDFSignerApp [OPTIONS]");
        System.out.println("Options:");
        System.out.println("  -i, --input-dir     Input directory containing PDF files (required)");
        System.out.println("  -o, --output-dir    Output directory for signed PDFs (required)");
        System.out.println("  -c, --cert          Path to the PFX certificate file (required)");
        System.out.println("  -p, --password      Password for the PFX certificate (required)");
        System.out.println("  -l, --location      Location for signature (default: Madrid)");
        System.out.println("  -r, --reason        Reason for signature (default: Document validation)");
        System.out.println("  -v, --visible       Make signature visible (default: false)");
        System.out.println("  -t, --timestamp     Add timestamp to signature (default: false)");
        System.out.println("  -h, --help          Display this help message");
    }

    private static void showGUI() {
        JFrame frame = new JFrame("PDF Signer");
        frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        frame.setSize(600, 500);
        frame.setLocationRelativeTo(null);

        JPanel panel = new JPanel();
        panel.setLayout(new GridBagLayout());
        GridBagConstraints gbc = new GridBagConstraints();
        gbc.fill = GridBagConstraints.HORIZONTAL;
        gbc.insets = new Insets(5, 5, 5, 5);

        // Input directory
        gbc.gridx = 0;
        gbc.gridy = 0;
        panel.add(new JLabel("Input Directory:"), gbc);

        JTextField inputDirField = new JTextField(30);
        gbc.gridx = 1;
        panel.add(inputDirField, gbc);

        JButton inputDirButton = new JButton("Browse...");
        gbc.gridx = 2;
        panel.add(inputDirButton, gbc);

        // Output directory
        gbc.gridx = 0;
        gbc.gridy = 1;
        panel.add(new JLabel("Output Directory:"), gbc);

        JTextField outputDirField = new JTextField(30);
        gbc.gridx = 1;
        panel.add(outputDirField, gbc);

        JButton outputDirButton = new JButton("Browse...");
        gbc.gridx = 2;
        panel.add(outputDirButton, gbc);

        // Certificate file
        gbc.gridx = 0;
        gbc.gridy = 2;
        panel.add(new JLabel("Certificate File:"), gbc);

        JTextField certField = new JTextField(30);
        gbc.gridx = 1;
        panel.add(certField, gbc);

        JButton certButton = new JButton("Browse...");
        gbc.gridx = 2;
        panel.add(certButton, gbc);

        // Password
        gbc.gridx = 0;
        gbc.gridy = 3;
        panel.add(new JLabel("Certificate Password:"), gbc);

        JPasswordField passwordField = new JPasswordField(30);
        gbc.gridx = 1;
        gbc.gridwidth = 2;
        panel.add(passwordField, gbc);

        // Location
        gbc.gridx = 0;
        gbc.gridy = 4;
        gbc.gridwidth = 1;
        panel.add(new JLabel("Signature Location:"), gbc);

        JTextField locationField = new JTextField(DEFAULT_LOCATION, 30);
        gbc.gridx = 1;
        gbc.gridwidth = 2;
        panel.add(locationField, gbc);

        // Reason
        gbc.gridx = 0;
        gbc.gridy = 5;
        gbc.gridwidth = 1;
        panel.add(new JLabel("Signature Reason:"), gbc);

        JTextField reasonField = new JTextField(DEFAULT_REASON, 30);
        gbc.gridx = 1;
        gbc.gridwidth = 2;
        panel.add(reasonField, gbc);

        // Checkboxes
        JCheckBox visibleCheckbox = new JCheckBox("Visible Signature", DEFAULT_VISIBLE);
        gbc.gridx = 0;
        gbc.gridy = 6;
        gbc.gridwidth = 1;
        panel.add(visibleCheckbox, gbc);

        JCheckBox timestampCheckbox = new JCheckBox("Add Timestamp", DEFAULT_TIMESTAMP);
        gbc.gridx = 1;
        panel.add(timestampCheckbox, gbc);

        // Status area
        JTextArea statusArea = new JTextArea(8, 40);
        statusArea.setEditable(false);
        JScrollPane scrollPane = new JScrollPane(statusArea);
        gbc.gridx = 0;
        gbc.gridy = 8;
        gbc.gridwidth = 3;
        gbc.fill = GridBagConstraints.BOTH;
        gbc.weightx = 1.0;
        gbc.weighty = 1.0;
        panel.add(scrollPane, gbc);

        // Sign button
        JButton signButton = new JButton("Sign PDFs");
        gbc.gridx = 0;
        gbc.gridy = 7;
        gbc.gridwidth = 3;
        gbc.fill = GridBagConstraints.HORIZONTAL;
        gbc.weightx = 0;
        gbc.weighty = 0;
        panel.add(signButton, gbc);

        // Directory choosers
        inputDirButton.addActionListener(e -> {
            JFileChooser chooser = new JFileChooser();
            chooser.setFileSelectionMode(JFileChooser.DIRECTORIES_ONLY);
            if (chooser.showOpenDialog(frame) == JFileChooser.APPROVE_OPTION) {
                inputDirField.setText(chooser.getSelectedFile().getAbsolutePath());
            }
        });

        outputDirButton.addActionListener(e -> {
            JFileChooser chooser = new JFileChooser();
            chooser.setFileSelectionMode(JFileChooser.DIRECTORIES_ONLY);
            if (chooser.showOpenDialog(frame) == JFileChooser.APPROVE_OPTION) {
                outputDirField.setText(chooser.getSelectedFile().getAbsolutePath());
            }
        });

        certButton.addActionListener(e -> {
            JFileChooser chooser = new JFileChooser();
            FileNameExtensionFilter filter = new FileNameExtensionFilter("Certificate Files", "pfx", "p12");
            chooser.setFileFilter(filter);
            if (chooser.showOpenDialog(frame) == JFileChooser.APPROVE_OPTION) {
                certField.setText(chooser.getSelectedFile().getAbsolutePath());
            }
        });

        // Sign button action
        signButton.addActionListener(e -> {
            String inputDir = inputDirField.getText().trim();
            String outputDir = outputDirField.getText().trim();
            String certPath = certField.getText().trim();
            char[] passwordChars = passwordField.getPassword();
            String password = new String(passwordChars);
            String location = locationField.getText().trim();
            String reason = reasonField.getText().trim();
            boolean visible = visibleCheckbox.isSelected();
            boolean timestamp = timestampCheckbox.isSelected();

            // Clear the password array for security
            java.util.Arrays.fill(passwordChars, '0');

            // Validate inputs
            if (inputDir.isEmpty() || outputDir.isEmpty() || certPath.isEmpty() || password.isEmpty()) {
                JOptionPane.showMessageDialog(frame, "All fields are required!", "Error", JOptionPane.ERROR_MESSAGE);
                return;
            }

            try {
                validatePath(inputDir, true, true);
                validatePath(outputDir, false, true);
                validatePath(certPath, true, false);
            } catch (IllegalArgumentException ex) {
                JOptionPane.showMessageDialog(frame, ex.getMessage(), "Error", JOptionPane.ERROR_MESSAGE);
                return;
            }

            // Disable GUI components during processing
            Component[] components = panel.getComponents();
            for (Component component : components) {
                component.setEnabled(false);
            }

            // Create a simple logger to update the status area
            final JTextAreaLogger logger = message -> {
                SwingUtilities.invokeLater(() -> {
                    statusArea.append(message + "\n");
                    statusArea.setCaretPosition(statusArea.getDocument().getLength());
                });
            };

            // Process PDFs in a separate thread
            new Thread(() -> {
                try {
                    processPDFs(inputDir, outputDir, certPath, password, location, reason, visible, timestamp, logger);
                    SwingUtilities.invokeLater(() -> {
                        JOptionPane.showMessageDialog(frame, "PDF signing completed successfully!", "Success", JOptionPane.INFORMATION_MESSAGE);
                        // Re-enable GUI components
                        for (Component component : components) {
                            component.setEnabled(true);
                        }
                    });
                } catch (Exception ex) {
                    final String errorMessage = ex.getMessage();
                    SwingUtilities.invokeLater(() -> {
                        JOptionPane.showMessageDialog(frame, "Error: " + errorMessage, "Error", JOptionPane.ERROR_MESSAGE);
                        // Re-enable GUI components
                        for (Component component : components) {
                            component.setEnabled(true);
                        }
                    });
                }
            }).start();
        });

        frame.add(panel);
        frame.setVisible(true);
    }

    private static void processPDFs(String inputDir, String outputDir, String certPath, String password,
                               String location, String reason, boolean visible, boolean timestamp) {
        processPDFs(inputDir, outputDir, certPath, password, location, reason, visible, timestamp, PDFSignerApp::logInfo);
    }

    private static void processPDFs(String inputDir, String outputDir, String certPath, String password,
                                    String location, String reason, boolean visible, boolean timestamp,
                                    JTextAreaLogger logger) {
        try {
            // Ensure output directory exists
            Path outputPath = Paths.get(outputDir);
            if (!Files.exists(outputPath)) {
                logger.log("Creating output directory: " + outputDir);
                Files.createDirectories(outputPath);
            }

            // Get list of PDF files in input directory
            File inputDirFile = new File(inputDir);
            File[] pdfFiles = inputDirFile.listFiles((dir, name) -> name.toLowerCase().endsWith(".pdf"));

            if (pdfFiles == null || pdfFiles.length == 0) {
                logger.log("No PDF files found in input directory: " + inputDir);
                return;
            }

            logger.log("Found " + pdfFiles.length + " PDF files to process");

            // Create temp config file for visible signature if needed
            File configFile = null;
            if (visible) {
                configFile = createSignatureConfigFile();
                logger.log("Created signature configuration file: " + configFile.getAbsolutePath());
            }

            // Find AutoFirma executable
            String autoFirmaPath = findAutoFirmaExecutable();
            if (autoFirmaPath == null) {
                throw new IOException("AutoFirma executable not found. Please ensure AutoFirma is installed.");
            }
            logger.log("Found AutoFirma executable: " + autoFirmaPath);

            // Process each PDF file
            int successCount = 0;
            int failCount = 0;

            for (File pdfFile : pdfFiles) {
                String inputFilePath = pdfFile.getAbsolutePath();
                String outputFilePath = Paths.get(outputDir, pdfFile.getName().replace(".pdf", "-signed.pdf")).toString();
                
                logger.log("Processing: " + pdfFile.getName());
                
                // Build AutoFirma command
                List<String> command = new ArrayList<>();
                command.add(autoFirmaPath);
                command.add("sign");
                command.add("-i");
                command.add(inputFilePath);
                command.add("-o");
                command.add(outputFilePath);
                command.add("-store");
                command.add("pkcs12:"+certPath);
                command.add("-password");
                command.add(password);
                command.add("-format");
                command.add("PAdES");
                
                if (location != null && !location.isEmpty()) {
                    command.add("-location");
                    command.add(location);
                }
                
                if (reason != null && !reason.isEmpty()) {
                    command.add("-reason");
                    command.add(reason);
                }
                
                if (visible && configFile != null) {
                    command.add("-config");
                    command.add(configFile.getAbsolutePath());
                }
                
                if (timestamp) {
                    command.add("-timestamp");
                }
                
                // Execute command
                ProcessBuilder pb = new ProcessBuilder(command);
                pb.redirectErrorStream(true);
                Process process = pb.start();
                
                // Read output
                StringBuilder output = new StringBuilder();
                try (java.io.BufferedReader reader = new java.io.BufferedReader(
                        new java.io.InputStreamReader(process.getInputStream()))) {
                    String line;
                    while ((line = reader.readLine()) != null) {
                        output.append(line).append("\n");
                    }
                }
                
                int exitCode = process.waitFor();
                
                if (exitCode == 0) {
                    logger.log("Successfully signed: " + pdfFile.getName());
                    successCount++;
                } else {
                    logger.log("Failed to sign: " + pdfFile.getName() + ", Exit code: " + exitCode);
                    logger.log("Error output: " + output.toString());
                    failCount++;
                }
            }
            
            // Delete temp config file if created
            if (configFile != null) {
                configFile.delete();
            }
            
            logger.log("PDF signing completed. Successfully signed: " + successCount + ", Failed: " + failCount);
            
        } catch (IOException | InterruptedException e) {
            throw new RuntimeException("Error processing PDF files: " + e.getMessage(), e);
        }
    }

    private static File createSignatureConfigFile() throws IOException {
        File configFile = File.createTempFile("signature", ".properties");
        try (FileWriter writer = new FileWriter(configFile)) {
            writer.write("signaturePositionOnPageLowerLeftX=" + SIG_X + "\n");
            writer.write("signaturePositionOnPageLowerLeftY=" + SIG_Y + "\n");
            writer.write("signaturePositionOnPageUpperRightX=" + (SIG_X + SIG_WIDTH) + "\n");
            writer.write("signaturePositionOnPageUpperRightY=" + (SIG_Y + SIG_HEIGHT) + "\n");
            writer.write("signaturePage=" + SIG_PAGE + "\n");
            writer.write("signatureRenderingMode=1\n"); // 0=description, 1=description and name, 2=sign image
            writer.write("signatureFontSize=" + SIG_FONT_SIZE + "\n");
            writer.write("signatureFontColor=" + SIG_FONT_COLOR + "\n");
            writer.write("signatureText=" + SIG_TEXT + "\n");
        }
        return configFile;
    }

    private static String findAutoFirmaExecutable() {
        String os = System.getProperty("os.name").toLowerCase();
        
        if (os.contains("win")) {
            // Windows
            String programFiles = System.getenv("ProgramFiles");
            String programFilesX86 = System.getenv("ProgramFiles(x86)");
            
            String[] possiblePaths = {
                programFiles + "\\AutoFirma\\AutoFirma.exe",
                programFilesX86 + "\\AutoFirma\\AutoFirma.exe"
            };
            
            for (String path : possiblePaths) {
                if (new File(path).exists()) {
                    return path;
                }
            }
        } else if (os.contains("mac")) {
            // macOS
            String[] possiblePaths = {
                "/Applications/AutoFirma.app/Contents/MacOS/AutoFirma",
                System.getProperty("user.home") + "/Applications/AutoFirma.app/Contents/MacOS/AutoFirma"
            };
            
            for (String path : possiblePaths) {
                if (new File(path).exists()) {
                    return path;
                }
            }
        } else {
            // Linux and others
            String[] possiblePaths = {
                "/usr/bin/autofirma",
                "/usr/local/bin/autofirma",
                "/opt/autofirma/autofirma"
            };
            
            for (String path : possiblePaths) {
                if (new File(path).exists()) {
                    return path;
                }
            }
        }
        
        return null;
    }
    
    // Logging methods
    private static void logInfo(String message) {
        log(message, "INFO");
    }
    
    private static void logError(String message) {
        log(message, "ERROR");
    }
    
    private static void log(String message, String level) {
        SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
        String timestamp = dateFormat.format(new Date());
        System.out.println("[" + timestamp + "] [" + level + "] " + message);
    }
    
    // Interface for logging to GUI
    private interface JTextAreaLogger {
        void log(String message);
    }
} 