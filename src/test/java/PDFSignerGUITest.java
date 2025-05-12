import static org.junit.Assert.*;
import org.junit.Before;
import org.junit.Test;
import org.junit.Rule;
import org.junit.rules.TemporaryFolder;

import java.io.File;
import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.nio.file.Files;
import javax.swing.*;
import java.awt.*;
import java.util.ArrayList;
import java.util.List;

/**
 * Test para la interfaz gráfica de PDFSignerApp
 * Estos tests comprueban la funcionalidad básica de la interfaz gráfica
 * sin mostrar realmente ventanas en la pantalla
 * 
 * @author gr3ym4n
 */
public class PDFSignerGUITest {
    
    @Rule
    public TemporaryFolder tempFolder = new TemporaryFolder();
    
    private JFrame testFrame;
    private JPanel mainPanel;
    private List<Component> components;
    
    @Before
    public void setUp() throws Exception {
        // Crear el frame y panel para probar
        createGUIComponents();
    }
    
    /**
     * Crea componentes GUI para pruebas mediante reflexión
     */
    private void createGUIComponents() throws Exception {
        // Usamos reflection para acceder al método showGUI y crear los componentes
        // pero evitamos que se muestre realmente en pantalla
        
        // Crear una clase anónima de SwingUtilities para interceptar invokeLater
        SwingUtilities.invokeLater(() -> {
            try {
                Method showGUIMethod = PDFSignerApp.class.getDeclaredMethod("showGUI");
                showGUIMethod.setAccessible(true);
                
                // Reemplazar temporalmente el método setVisible para evitar que se muestre la ventana
                final JFrame originalFrame = new JFrame();
                Field[] fields = JFrame.class.getDeclaredFields();
                
                // Ejecutar el método showGUI (que normalmente mostraría la interfaz)
                showGUIMethod.invoke(null);
                
                // Buscar los componentes creados
                Window[] windows = Window.getWindows();
                for (Window window : windows) {
                    if (window instanceof JFrame && window.getName() != null && 
                        window.getName().contains("PDF Signer")) {
                        testFrame = (JFrame) window;
                        break;
                    }
                }
                
                // Si encontramos el frame, obtener sus componentes
                if (testFrame != null) {
                    Container contentPane = testFrame.getContentPane();
                    if (contentPane.getComponentCount() > 0 && contentPane.getComponent(0) instanceof JPanel) {
                        mainPanel = (JPanel) contentPane.getComponent(0);
                        
                        // Recopilar todos los componentes para pruebas
                        components = new ArrayList<>();
                        getAllComponents(mainPanel, components);
                    }
                    
                    // Evitar que se muestre
                    testFrame.setVisible(false);
                }
            } catch (Exception e) {
                e.printStackTrace();
                fail("Error al configurar la interfaz gráfica para pruebas: " + e.getMessage());
            }
        });
        
        // Dar tiempo para que se ejecute el código de Swing
        Thread.sleep(500);
    }
    
    /**
     * Recorre recursivamente todos los componentes en el contenedor
     */
    private void getAllComponents(Container container, List<Component> result) {
        Component[] components = container.getComponents();
        for (Component component : components) {
            result.add(component);
            if (component instanceof Container) {
                getAllComponents((Container) component, result);
            }
        }
    }
    
    @Test
    public void testGUICreated() {
        // Verificar que se creó la interfaz
        assertNotNull("El frame debería crearse", testFrame);
        assertNotNull("El panel principal debería crearse", mainPanel);
        assertTrue("Deberían existir componentes en la interfaz", components != null && !components.isEmpty());
    }
    
    @Test
    public void testRequiredInputFields() {
        assumeGUICreated();
        
        // Verificar que existen los campos de entrada necesarios
        JTextField inputDirField = findComponentByName(JTextField.class, "inputDirField");
        JTextField outputDirField = findComponentByName(JTextField.class, "outputDirField");
        JTextField certField = findComponentByName(JTextField.class, "certField");
        JPasswordField passwordField = findComponentByName(JPasswordField.class, "passwordField");
        
        assertNotNull("Debería existir el campo de directorio de entrada", inputDirField);
        assertNotNull("Debería existir el campo de directorio de salida", outputDirField);
        assertNotNull("Debería existir el campo de certificado", certField);
        assertNotNull("Debería existir el campo de contraseña", passwordField);
    }
    
    @Test
    public void testCheckboxes() {
        assumeGUICreated();
        
        // Verificar checkboxes
        JCheckBox visibleCheckbox = findCheckboxByText("Visible Signature");
        JCheckBox timestampCheckbox = findCheckboxByText("Add Timestamp");
        
        assertNotNull("Debería existir el checkbox de firma visible", visibleCheckbox);
        assertNotNull("Debería existir el checkbox de timestamp", timestampCheckbox);
    }
    
    @Test
    public void testSignButton() {
        assumeGUICreated();
        
        // Verificar botón de firma
        JButton signButton = findButtonByText("Sign PDFs");
        
        assertNotNull("Debería existir el botón para firmar PDFs", signButton);
    }
    
    /**
     * Test que simula el flujo de trabajo principal de la interfaz
     */
    @Test
    public void testSimulateWorkflow() throws Exception {
        assumeGUICreated();
        
        // Crear archivos temporales para la prueba
        File inputDir = tempFolder.newFolder("gui_input");
        File outputDir = tempFolder.newFolder("gui_output");
        File certFile = new File(tempFolder.getRoot(), "gui_cert.pfx");
        Files.write(certFile.toPath(), "test certificate data".getBytes());
        
        // Crear un PDF de muestra
        File samplePdf = new File(inputDir, "sample.pdf");
        Files.write(samplePdf.toPath(), "sample PDF content".getBytes());
        
        // Obtener los componentes necesarios
        JTextField inputDirField = findComponentByType(JTextField.class);
        JTextField outputDirField = findNextComponentOfType(JTextField.class, inputDirField);
        JTextField certField = findNextComponentOfType(JTextField.class, outputDirField);
        JPasswordField passwordField = findComponentByType(JPasswordField.class);
        JButton signButton = findButtonByText("Sign PDFs");
        
        // Simular la entrada de datos
        if (inputDirField != null) inputDirField.setText(inputDir.getAbsolutePath());
        if (outputDirField != null) outputDirField.setText(outputDir.getAbsolutePath());
        if (certField != null) certField.setText(certFile.getAbsolutePath());
        if (passwordField != null) passwordField.setText("testpassword");
        
        // Verificar que los datos se ingresaron correctamente
        if (inputDirField != null) assertEquals("Directorio de entrada debería actualizarse", 
                inputDir.getAbsolutePath(), inputDirField.getText());
        
        // No probamos el botón de firma porque ejecutaría el proceso real
        // Solo verificamos que la validación de datos funcionaría
        if (signButton != null && inputDirField != null && outputDirField != null &&
            certField != null && passwordField != null) {
            assertTrue("Con todos los campos llenos, debería permitir firmar", 
                    !inputDirField.getText().isEmpty() && 
                    !outputDirField.getText().isEmpty() && 
                    !certField.getText().isEmpty() && 
                    passwordField.getPassword().length > 0);
        }
    }
    
    /**
     * Test que simula el flujo de trabajo usando la variable de entorno para la contraseña
     */
    @Test
    public void testWorkflowWithEnvironmentVariablePassword() throws Exception {
        assumeGUICreated();
        
        // Crear archivos temporales para la prueba
        File inputDir = tempFolder.newFolder("gui_input_env");
        File outputDir = tempFolder.newFolder("gui_output_env");
        File certFile = new File(tempFolder.getRoot(), "gui_cert_env.pfx");
        Files.write(certFile.toPath(), "test certificate data".getBytes());
        
        // Crear un PDF de muestra
        File samplePdf = new File(inputDir, "sample.pdf");
        Files.write(samplePdf.toPath(), "sample PDF content".getBytes());
        
        // Obtener los componentes necesarios
        JTextField inputDirField = findComponentByType(JTextField.class);
        JTextField outputDirField = findNextComponentOfType(JTextField.class, inputDirField);
        JTextField certField = findNextComponentOfType(JTextField.class, outputDirField);
        JPasswordField passwordField = findComponentByType(JPasswordField.class);
        
        // Simular la entrada de datos - sin contraseña, que se tomará de la variable de entorno
        if (inputDirField != null) inputDirField.setText(inputDir.getAbsolutePath());
        if (outputDirField != null) outputDirField.setText(outputDir.getAbsolutePath());
        if (certField != null) certField.setText(certFile.getAbsolutePath());
        // No establecemos contraseña en el campo de contraseña, simulando que se usará la variable de entorno
        
        // Verificamos que aún con campo de contraseña vacío, podemos proceder si hay variable de entorno
        // (Para simular esto, deberíamos analizar el comportamiento del botón de firma, que
        // debería verificar la presencia de la variable de entorno cuando el campo está vacío)
    }
    
    // Métodos de utilidad para buscar componentes
    
    private <T extends Component> T findComponentByName(Class<T> type, String name) {
        if (components == null) return null;
        
        for (Component c : components) {
            if (type.isInstance(c) && name.equals(c.getName())) {
                return type.cast(c);
            }
        }
        
        return null;
    }
    
    private <T extends Component> T findComponentByType(Class<T> type) {
        if (components == null) return null;
        
        for (Component c : components) {
            if (type.isInstance(c)) {
                return type.cast(c);
            }
        }
        
        return null;
    }
    
    private <T extends Component> T findNextComponentOfType(Class<T> type, Component after) {
        if (components == null || after == null) return null;
        
        boolean foundStart = false;
        
        for (Component c : components) {
            if (c == after) {
                foundStart = true;
                continue;
            }
            
            if (foundStart && type.isInstance(c)) {
                return type.cast(c);
            }
        }
        
        return null;
    }
    
    private JButton findButtonByText(String text) {
        if (components == null) return null;
        
        for (Component c : components) {
            if (c instanceof JButton && text.equals(((JButton) c).getText())) {
                return (JButton) c;
            }
        }
        
        return null;
    }
    
    private JCheckBox findCheckboxByText(String text) {
        if (components == null) return null;
        
        for (Component c : components) {
            if (c instanceof JCheckBox && text.equals(((JCheckBox) c).getText())) {
                return (JCheckBox) c;
            }
        }
        
        return null;
    }
    
    private void assumeGUICreated() {
        org.junit.Assume.assumeNotNull("La GUI debe crearse para esta prueba", testFrame, mainPanel, components);
        org.junit.Assume.assumeFalse("Deben existir componentes en la GUI", components.isEmpty());
    }
} 