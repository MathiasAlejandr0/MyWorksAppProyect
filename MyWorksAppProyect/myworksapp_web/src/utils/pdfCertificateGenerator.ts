export interface CertificateData {
  certificateId: string;
  clientName: string;
  workerName: string;
  profession: string;
  serviceDate: string;
  totalAmount: number;
  pinCode: string;
  transactionHash: string;
}

/** Escapa texto para inserción segura en HTML (previene XSS vía document.write). */
function escapeHtml(value: string): string {
  return value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

export function generatePdfCertificate(data: CertificateData) {
  const printWindow = window.open('', '_blank');
  if (!printWindow) return;

  const certificateId = escapeHtml(data.certificateId);
  const clientName = escapeHtml(data.clientName);
  const workerName = escapeHtml(data.workerName);
  const profession = escapeHtml(data.profession);
  const serviceDate = escapeHtml(data.serviceDate);
  const pinTail = escapeHtml(data.pinCode.slice(-2));
  const transactionHash = escapeHtml(data.transactionHash);
  const totalFormatted = escapeHtml(data.totalAmount.toLocaleString('es-CL'));

  const htmlContent = `
    <!DOCTYPE html>
    <html lang="es">
    <head>
      <meta charset="UTF-8">
      <title>Comprobante de servicio MyWorks (demo) - ${certificateId}</title>
      <style>
        body { font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; color: #1D1D1F; padding: 40px; background-color: #F8F9FA; }
        .certificate-card { max-width: 700px; margin: 0 auto; background: #FFF; border-radius: 16px; padding: 40px; border: 2px solid #F0782A; box-shadow: 0 10px 30px rgba(0,0,0,0.1); }
        .header { display: flex; justify-content: space-between; align-items: center; border-bottom: 2px solid #F2F2F7; padding-bottom: 20px; margin-bottom: 30px; }
        .logo { font-size: 24px; font-weight: 900; color: #0B192C; }
        .logo span { color: #F0782A; }
        .badge { background: #FFF4EE; color: #F0782A; padding: 6px 16px; border-radius: 20px; font-weight: 800; font-size: 13px; }
        .title { text-align: center; margin-bottom: 30px; }
        .title h1 { font-size: 22px; margin-bottom: 6px; }
        .title p { color: #8E8E93; font-size: 13px; }
        .info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; background: #F8F9FA; padding: 20px; border-radius: 12px; margin-bottom: 30px; }
        .info-item { font-size: 13px; }
        .info-item label { color: #8E8E93; display: block; font-size: 11px; font-weight: 700; text-transform: uppercase; margin-bottom: 2px; }
        .info-item value { font-weight: 800; }
        .demo-box { background: #FFF8E6; border: 1px solid #E89B2D; border-radius: 12px; padding: 16px; text-align: center; margin-bottom: 30px; }
        .footer { text-align: center; font-size: 11px; color: #8E8E93; border-top: 1px solid #F2F2F7; padding-top: 20px; }
      </style>
    </head>
    <body>
      <div class="certificate-card">
        <div class="header">
          <div class="logo">MyWorks <span>App</span></div>
          <div class="badge">DEMO · SIN COBRO REAL</div>
        </div>

        <div class="title">
          <h1>Comprobante de servicio (simulación)</h1>
          <p>N°: ${certificateId} | Fecha: ${serviceDate}</p>
        </div>

        <div class="info-grid">
          <div class="info-item">
            <label>Cliente</label>
            <value>${clientName}</value>
          </div>
          <div class="info-item">
            <label>Profesional</label>
            <value>${workerName} (${profession})</value>
          </div>
          <div class="info-item">
            <label>Monto referencial</label>
            <value>$${totalFormatted} CLP</value>
          </div>
          <div class="info-item">
            <label>PIN (demo)</label>
            <value>**** ${pinTail}</value>
          </div>
        </div>

        <div class="demo-box">
          <h3 style="color: #E89B2D; margin-bottom: 4px;">Simulación / demo</h3>
          <p style="font-size: 12px; margin: 0;">Este documento no constituye pago real ni garantía legal. Ref: <code>${transactionHash}</code></p>
        </div>

        <div class="footer">
          <p>MyWorks App Chile — comprobante de demostración del flujo web de clientes.</p>
        </div>
      </div>
      <script>
        window.onload = function() { window.print(); }
      </script>
    </body>
    </html>
  `;

  printWindow.document.write(htmlContent);
  printWindow.document.close();
}
