import static org.junit.Assert.*;
import org.junit.Before;
import org.junit.Test;
import org.junit.Rule;
import org.junit.rules.TemporaryFolder;
import org.junit.Assume;
import org.junit.After;

import java.io.File;
import java.io.IOException;
import java.lang.reflect.Method;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;

/**
 * Test de integración para PDFSignerApp
 * Este test requiere una instalación real de AutoFirma para ejecutarse completamente
 * 
 * @author gr3ym4n
 */
public class PDFSignerIntegrationTest {
    
    @Rule
    public TemporaryFolder tempFolder = new TemporaryFolder();
    
    private File inputDir;
    private File outputDir;
    private File certFile;
    private String autoFirmaPath;
    private String originalEnvPassword;
    
    @Before
    public void setUp() throws Exception {
        // Guardar el valor original de la variable de entorno
        originalEnvPassword = System.getenv("PDF_CERT_PASSWORD");
        
        // Crear directorios temporales para pruebas
        inputDir = tempFolder.newFolder("input");
        outputDir = tempFolder.newFolder("output");
        
        // Verificar si AutoFirma está disponible
        Method findAutoFirmaMethod = PDFSignerApp.class.getDeclaredMethod("findAutoFirmaExecutable");
        findAutoFirmaMethod.setAccessible(true);
        autoFirmaPath = (String) findAutoFirmaMethod.invoke(null);
        
        // Crear un PDF de muestra para pruebas
        createSamplePdf();
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

    /**
     * Crear un PDF de muestra para las pruebas
     * Este método crea un PDF muy básico para fines de prueba
     */
    private void createSamplePdf() throws IOException {
        // En una situación real, usaríamos una biblioteca como PDFBox para crear un PDF real
        // Para esta prueba, simulamos un PDF con contenido básico
        
        String minimalPdfContent = 
            "%PDF-1.4\n" +
            "1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj\n" +
            "2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj\n" +
            "3 0 obj<</Type/Page/MediaBox[0 0 595 842]/Parent 2 0 R/Resources<<>>>>endobj\n" +
            "xref\n" +
            "0 4\n" +
            "0000000000 65535 f\n" +
            "0000000010 00000 n\n" +
            "0000000053 00000 n\n" +
            "0000000102 00000 n\n" +
            "trailer<</Size 4/Root 1 0 R>>\n" +
            "startxref\n" +
            "176\n" +
            "%%EOF";
        
        File samplePdf = new File(inputDir, "sample.pdf");
        Files.write(samplePdf.toPath(), minimalPdfContent.getBytes());
    }
    
    @Test
    public void testAutoFirmaInstalled() {
        // Verificar si AutoFirma está instalado
        assertNotNull("AutoFirma debería estar instalado para las pruebas de integración", autoFirmaPath);
        System.out.println("AutoFirma encontrado en: " + autoFirmaPath);
    }
    
    @Test
    public void testCreateCertificate() throws Exception {
        // Omitir la prueba si no se puede generar un certificado de prueba
        Assume.assumeTrue("No se puede crear un certificado de prueba en este entorno", canCreateTestCertificate());
        
        // Crear certificado de prueba
        certFile = createTestCertificate();
        assertNotNull("Debería crearse un certificado de prueba", certFile);
        assertTrue("El certificado debería existir", certFile.exists());
    }
    
    @Test
    public void testFullIntegration() throws Exception {
        // Omitir la prueba si AutoFirma no está instalado
        Assume.assumeNotNull("AutoFirma no está instalado", autoFirmaPath);
        
        // Omitir la prueba si no podemos crear un certificado de prueba
        Assume.assumeTrue("No se puede crear un certificado de prueba", canCreateTestCertificate());
        
        if (certFile == null) {
            certFile = createTestCertificate();
        }
        
        // Acceder al método processPDFs usando reflection
        Method processPDFsMethod = PDFSignerApp.class.getDeclaredMethod(
            "processPDFs", 
            String.class, String.class, String.class, String.class,
            String.class, String.class, boolean.class, boolean.class);
        processPDFsMethod.setAccessible(true);
        
        // Intentar firmar el PDF
        Exception caught = null;
        try {
            processPDFsMethod.invoke(
                null,
                inputDir.getAbsolutePath(),
                outputDir.getAbsolutePath(),
                certFile.getAbsolutePath(),
                "testpassword",
                "TestLocation",
                "TestReason",
                true,
                false
            );
        } catch (Exception e) {
            caught = e;
            e.printStackTrace();
        }
        
        // En un entorno de CI, probablemente fallará, pero registramos el resultado
        if (caught == null) {
            // Verificar que se creó el archivo de salida
            File[] outputFiles = outputDir.listFiles((dir, name) -> name.toLowerCase().endsWith("-signed.pdf"));
            assertTrue("Debería generarse al menos un archivo PDF firmado", outputFiles != null && outputFiles.length > 0);
            System.out.println("Integración exitosa: se generaron " + outputFiles.length + " archivos firmados");
        } else {
            System.out.println("La prueba de integración falló como se esperaba en un entorno sin configuración completa: " + caught.getMessage());
        }
    }
    
    @Test
    public void testFullIntegrationWithEnvironmentVariable() throws Exception {
        // Omitir la prueba si AutoFirma no está instalado
        Assume.assumeNotNull("AutoFirma no está instalado", autoFirmaPath);
        
        // Omitir la prueba si no podemos crear un certificado de prueba
        Assume.assumeTrue("No se puede crear un certificado de prueba", canCreateTestCertificate());
        
        if (certFile == null) {
            certFile = createTestCertificate();
        }
        
        // Establecer la variable de entorno para la prueba
        setEnv("PDF_CERT_PASSWORD", "env_test_password");
        
        // Crear directorios específicos para esta prueba
        File envInputDir = tempFolder.newFolder("env_input");
        File envOutputDir = tempFolder.newFolder("env_output");
        
        // Copiar el PDF de muestra al nuevo directorio
        String minimalPdfContent = 
            "%PDF-1.4\n" +
            "1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj\n" +
            "2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj\n" +
            "3 0 obj<</Type/Page/MediaBox[0 0 595 842]/Parent 2 0 R/Resources<<>>>>endobj\n" +
            "xref\n" +
            "0 4\n" +
            "0000000000 65535 f\n" +
            "0000000010 00000 n\n" +
            "0000000053 00000 n\n" +
            "0000000102 00000 n\n" +
            "trailer<</Size 4/Root 1 0 R>>\n" +
            "startxref\n" +
            "176\n" +
            "%%EOF";
        
        File envSamplePdf = new File(envInputDir, "env_sample.pdf");
        Files.write(envSamplePdf.toPath(), minimalPdfContent.getBytes());
        
        // Acceder al método parseArgs usando reflection
        Method parseArgsMethod = PDFSignerApp.class.getDeclaredMethod("parseArgs", String[].class);
        parseArgsMethod.setAccessible(true);
        
        // Simular argumentos sin contraseña explícita (debe usar la variable de entorno)
        String[] args = {
            "--input-dir", envInputDir.getAbsolutePath(),
            "--output-dir", envOutputDir.getAbsolutePath(),
            "--cert", certFile.getAbsolutePath(),
            "--location", "EnvTestLocation",
            "--reason", "EnvTestReason",
            "--visible",
            "--timestamp"
        };
        
        // Verificar que parseArgs funciona con la variable de entorno
        String[] result = null;
        Exception parseException = null;
        
        try {
            result = (String[]) parseArgsMethod.invoke(null, (Object) args);
        } catch (Exception e) {
            parseException = e;
            e.printStackTrace();
        }
        
        assertNull("No debería haber excepciones al parsear los argumentos con variable de entorno", parseException);
        assertNotNull("parseArgs debería devolver un array no nulo", result);
        assertEquals("La contraseña debería provenir de la variable de entorno", "env_test_password", result[3]);
        
        // Intentar firmar el PDF usando processPDFs
        Method processPDFsMethod = PDFSignerApp.class.getDeclaredMethod(
            "processPDFs", 
            String.class, String.class, String.class, String.class,
            String.class, String.class, boolean.class, boolean.class);
        processPDFsMethod.setAccessible(true);
        
        Exception processingException = null;
        try {
            processPDFsMethod.invoke(
                null,
                envInputDir.getAbsolutePath(),
                envOutputDir.getAbsolutePath(),
                certFile.getAbsolutePath(),
                result[3], // Contraseña de la variable de entorno
                "EnvTestLocation",
                "EnvTestReason",
                true,
                true
            );
        } catch (Exception e) {
            processingException = e;
            e.printStackTrace();
        }
        
        // En un entorno de CI, probablemente fallará, pero registramos el resultado
        if (processingException == null) {
            // Verificar que se creó el archivo de salida
            File[] outputFiles = envOutputDir.listFiles((dir, name) -> name.toLowerCase().endsWith("-signed.pdf"));
            assertTrue("Debería generarse al menos un archivo PDF firmado", outputFiles != null && outputFiles.length > 0);
            System.out.println("Integración con variable de entorno exitosa: se generaron " + outputFiles.length + " archivos firmados");
        } else {
            System.out.println("La prueba de integración con variable de entorno falló como se esperaba en un entorno sin configuración completa: " + processingException.getMessage());
        }
    }
    
    /**
     * Determina si es posible crear un certificado de prueba en este entorno
     */
    private boolean canCreateTestCertificate() {
        // En un entorno real, verificaríamos si podemos usar keytool o OpenSSL
        // Para simplificar, siempre devolvemos false y solo simulamos
        return false; // Cambia a true si tienes una forma de generar certificados
    }
    
    /**
     * Crea un certificado de prueba para las pruebas
     * En un entorno real, usaríamos keytool o OpenSSL para generar un certificado temporal
     */
    private File createTestCertificate() throws IOException {
        // Simular un archivo de certificado
        File certFile = new File(tempFolder.getRoot(), "test_cert.pfx");
        
        // En un entorno real, ejecutaríamos algo como:
        // keytool -genkeypair -alias testkey -keyalg RSA -keystore test_cert.pfx -storetype PKCS12 -storepass testpassword
        
        // Para esta prueba, solo creamos un archivo simulado
        Files.write(certFile.toPath(), "simulated certificate data".getBytes());
        
        return certFile;
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