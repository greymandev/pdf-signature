import static org.junit.Assert.*;
import org.junit.Before;
import org.junit.Test;
import org.junit.Rule;
import org.junit.rules.TemporaryFolder;
import org.junit.After;

import java.io.File;
import java.lang.reflect.Method;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;

/**
 * Test unitario para validar PDFSignerApp
 * 
 * @author gr3ym4n
 */
public class PDFSignerAppTest {
    
    @Rule
    public TemporaryFolder tempFolder = new TemporaryFolder();
    
    private File inputDir;
    private File outputDir;
    private File certFile;
    private File dummyPdf;
    private String originalEnvPassword;
    
    @Before
    public void setUp() throws Exception {
        // Guardar el valor original de la variable de entorno
        originalEnvPassword = System.getenv("PDF_CERT_PASSWORD");
        
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
    
    @After
    public void tearDown() {
        // Restaurar el entorno original
        if (originalEnvPassword != null) {
            setEnv("PDF_CERT_PASSWORD", originalEnvPassword);
        } else {
            clearEnv("PDF_CERT_PASSWORD");
        }
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
    
    @Test
    public void testParseArgsUsingEnvironmentVariable() throws Exception {
        // Establecer variable de entorno para la prueba
        setEnv("PDF_CERT_PASSWORD", "env_test_password");
        
        // Acceder al método parseArgs usando reflection
        Method parseArgsMethod = PDFSignerApp.class.getDeclaredMethod("parseArgs", String[].class);
        parseArgsMethod.setAccessible(true);
        
        // No incluimos el parámetro --password ya que debe tomarlo de la variable de entorno
        String[] args = {
            "--input-dir", inputDir.getAbsolutePath(),
            "--output-dir", outputDir.getAbsolutePath(),
            "--cert", certFile.getAbsolutePath()
        };
        
        String[] result = (String[]) parseArgsMethod.invoke(null, (Object) args);
        
        assertNotNull("parseArgs debería devolver un array no nulo", result);
        assertEquals("La contraseña debería obtenerse de la variable de entorno", "env_test_password", result[3]);
    }
    
    @Test
    public void testParseArgsUsingCustomEnvironmentVariable() throws Exception {
        // Establecer variable de entorno para la prueba
        setEnv("CUSTOM_PASSWORD_VAR", "custom_env_password");
        
        // Acceder al método parseArgs usando reflection
        Method parseArgsMethod = PDFSignerApp.class.getDeclaredMethod("parseArgs", String[].class);
        parseArgsMethod.setAccessible(true);
        
        String[] args = {
            "--input-dir", inputDir.getAbsolutePath(),
            "--output-dir", outputDir.getAbsolutePath(),
            "--cert", certFile.getAbsolutePath(),
            "--password-env", "CUSTOM_PASSWORD_VAR"
        };
        
        String[] result = (String[]) parseArgsMethod.invoke(null, (Object) args);
        
        assertNotNull("parseArgs debería devolver un array no nulo", result);
        assertEquals("La contraseña debería obtenerse de la variable de entorno personalizada", 
                "custom_env_password", result[3]);
        
        // Limpiar variable de entorno de prueba
        clearEnv("CUSTOM_PASSWORD_VAR");
    }
    
    @Test
    public void testParseArgsUsingPasswordFile() throws Exception {
        // Crear un archivo de contraseña de prueba
        File passwordFile = new File(tempFolder.getRoot(), "password.txt");
        Files.write(passwordFile.toPath(), "file_password".getBytes());
        
        // Acceder al método parseArgs usando reflection
        Method parseArgsMethod = PDFSignerApp.class.getDeclaredMethod("parseArgs", String[].class);
        parseArgsMethod.setAccessible(true);
        
        String[] args = {
            "--input-dir", inputDir.getAbsolutePath(),
            "--output-dir", outputDir.getAbsolutePath(),
            "--cert", certFile.getAbsolutePath(),
            "--password-file", passwordFile.getAbsolutePath()
        };
        
        String[] result = (String[]) parseArgsMethod.invoke(null, (Object) args);
        
        assertNotNull("parseArgs debería devolver un array no nulo", result);
        assertEquals("La contraseña debería obtenerse del archivo", "file_password", result[3]);
    }
    
    @Test(expected = Exception.class)
    public void testParseArgsMissingAllPasswordMethods() throws Exception {
        // Asegurar que no hay variable de entorno de contraseña
        clearEnv("PDF_CERT_PASSWORD");
        
        // Acceder al método parseArgs usando reflection
        Method parseArgsMethod = PDFSignerApp.class.getDeclaredMethod("parseArgs", String[].class);
        parseArgsMethod.setAccessible(true);
        
        // Faltan todos los métodos de contraseña (directa, env, file, prompt)
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
    
    // Métodos de utilidad para manejar variables de entorno
    
    private void setEnv(String name, String value) {
        try {
            java.lang.reflect.Field field = System.getenv().getClass().getDeclaredField("m");
            field.setAccessible(true);
            java.util.Map<String, String> env = (java.util.Map<String, String>) field.get(System.getenv());
            if (value == null) {
                env.remove(name);
            } else {
                env.put(name, value);
            }
        } catch (Exception e) {
            throw new RuntimeException("No se pudo establecer la variable de entorno", e);
        }
    }
    
    private void clearEnv(String name) {
        setEnv(name, null);
    }
} 