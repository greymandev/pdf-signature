import static org.junit.Assert.*;
import org.junit.Before;
import org.junit.Test;
import org.junit.Rule;
import org.junit.rules.TemporaryFolder;

import java.io.File;
import java.lang.reflect.Method;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;

/**
 * Test unitario para validar PDFSignerApp
 */
public class PDFSignerAppTest {
    
    @Rule
    public TemporaryFolder tempFolder = new TemporaryFolder();
    
    private File inputDir;
    private File outputDir;
    private File certFile;
    private File dummyPdf;
    
    @Before
    public void setUp() throws Exception {
        // Crear directorios temporales para pruebas
        inputDir = tempFolder.newFolder("input");
        outputDir = tempFolder.newFolder("output");
        
        // Crear un archivo de certificado ficticio
        certFile = new File(tempFolder.getRoot(), "test_cert.pfx");
        Files.write(certFile.toPath(), "dummy certificate data".getBytes());
        
        // Crear un PDF ficticio para probar
        dummyPdf = new File(inputDir, "test.pdf");
        Files.write(dummyPdf.toPath(), "dummy PDF content".getBytes());
    }
    
    @Test
    public void testParseValidArgs() throws Exception {
        // Acceder al método parseArgs usando reflection
        Method parseArgsMethod = PDFSignerApp.class.getDeclaredMethod("parseArgs", String[].class);
        parseArgsMethod.setAccessible(true);
        
        String[] args = {
            "--input-dir", inputDir.getAbsolutePath(),
            "--output-dir", outputDir.getAbsolutePath(),
            "--cert", certFile.getAbsolutePath(),
            "--password", "testpassword",
            "--location", "Madrid",
            "--reason", "Testing",
            "--visible",
            "--timestamp"
        };
        
        String[] result = (String[]) parseArgsMethod.invoke(null, (Object) args);
        
        assertNotNull("parseArgs debería devolver un array no nulo", result);
        assertEquals("El directorio de entrada debería ser correcto", inputDir.getAbsolutePath(), result[0]);
        assertEquals("El directorio de salida debería ser correcto", outputDir.getAbsolutePath(), result[1]);
        assertEquals("La ruta del certificado debería ser correcta", certFile.getAbsolutePath(), result[2]);
        assertEquals("La contraseña debería ser correcta", "testpassword", result[3]);
        assertEquals("La ubicación debería ser correcta", "Madrid", result[4]);
        assertEquals("La razón debería ser correcta", "Testing", result[5]);
        assertEquals("Visible debería ser true", "true", result[6]);
        assertEquals("Timestamp debería ser true", "true", result[7]);
    }
    
    @Test(expected = Exception.class)
    public void testParseArgsMissingRequired() throws Exception {
        // Acceder al método parseArgs usando reflection
        Method parseArgsMethod = PDFSignerApp.class.getDeclaredMethod("parseArgs", String[].class);
        parseArgsMethod.setAccessible(true);
        
        // Falta el parámetro obligatorio --password
        String[] args = {
            "--input-dir", inputDir.getAbsolutePath(),
            "--output-dir", outputDir.getAbsolutePath(),
            "--cert", certFile.getAbsolutePath()
        };
        
        parseArgsMethod.invoke(null, (Object) args);
        // Debería lanzar una excepción
    }
    
    @Test
    public void testCreateSignatureConfigFile() throws Exception {
        // Acceder al método createSignatureConfigFile usando reflection
        Method createConfigMethod = PDFSignerApp.class.getDeclaredMethod("createSignatureConfigFile");
        createConfigMethod.setAccessible(true);
        
        File configFile = (File) createConfigMethod.invoke(null);
        
        assertTrue("El archivo de configuración debería existir", configFile.exists());
        assertTrue("El archivo de configuración debería tener contenido", configFile.length() > 0);
        
        String content = new String(Files.readAllBytes(configFile.toPath()));
        assertTrue("El archivo de configuración debería contener parámetros de firma", 
                content.contains("signaturePositionOnPageLowerLeftX=") &&
                content.contains("signatureText="));
        
        // Limpiar
        configFile.delete();
    }
    
    @Test
    public void testFindAutoFirmaExecutable() throws Exception {
        // Acceder al método findAutoFirmaExecutable usando reflection
        Method findAutoFirmaMethod = PDFSignerApp.class.getDeclaredMethod("findAutoFirmaExecutable");
        findAutoFirmaMethod.setAccessible(true);
        
        // Este test podría fallar si AutoFirma no está instalado
        // Solo comprobamos que el método se ejecuta sin errores
        findAutoFirmaMethod.invoke(null);
    }
    
    @Test
    public void testValidatePath() throws Exception {
        // Acceder al método validatePath usando reflection
        Method validatePathMethod = PDFSignerApp.class.getDeclaredMethod(
            "validatePath", String.class, boolean.class, boolean.class);
        validatePathMethod.setAccessible(true);
        
        // Validar path existente
        validatePathMethod.invoke(null, inputDir.getAbsolutePath(), true, true);
        
        // Crear un archivo temporal para probar la validación de no-directorio
        File tempFile = new File(tempFolder.getRoot(), "test.txt");
        Files.write(tempFile.toPath(), "test content".getBytes());
        
        try {
            validatePathMethod.invoke(null, tempFile.getAbsolutePath(), true, true);
            fail("Debería lanzar una excepción para un archivo cuando se espera un directorio");
        } catch (Exception e) {
            // Esperado
        }
        
        // Validar un path que no existe pero no es obligatorio que exista
        File nonExistentDir = new File(tempFolder.getRoot(), "nonexistent");
        validatePathMethod.invoke(null, nonExistentDir.getAbsolutePath(), false, true);
    }
    
    // Este test simula la validación de integración sin ejecutar realmente AutoFirma
    @Test
    public void testIntegrationSimulation() throws Exception {
        // Este test sólo verifica que la estructura básica de la aplicación funciona
        // sin realmente intentar firmar PDFs
        
        // Crear un directorio de entrada con múltiples PDFs
        for (int i = 1; i <= 3; i++) {
            File pdf = new File(inputDir, "test" + i + ".pdf");
            Files.write(pdf.toPath(), ("dummy PDF content " + i).getBytes());
        }
        
        // Verificar que el directorio de salida está vacío inicialmente
        assertEquals("El directorio de salida debería estar vacío", 0, outputDir.list().length);
        
        // En un test real, aquí llamaríamos a processPDFs, pero como depende de AutoFirma,
        // no lo hacemos en este test unitario
    }
} 