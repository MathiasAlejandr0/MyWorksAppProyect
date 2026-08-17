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

export function generatePdfCertificate(data: CertificateData) {
  const printWindow = window.open('', '_blank');
  if (!printWindow) return;

  const htmlContent = `
    <!DOCTYPE html>
    <html lang="es">
    <head>
      <meta charset="UTF-8">
      <title>Certificado de Servicio MyWorks Protect - ${data.certificateId}</title>
      <style>
        body { font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; color: #1D1D1F; padding: 40px; background-color: #F8F9FA; }
        .certificate-card { max-width: 700px; margin: 0 auto; background: #FFF; border-radius: 16px; padding: 40px; border: 2px solid #F0782A; box-shadow: 0 10px 30px rgba(0,0,0,0.1); }
        .header { display: flex; justify-content: space-between; align-items: center; border-bottom: 2px solid #F2F2F7; padding-bottom: 20px; margin-bottom: 30px; }
        .logo { font-size: 24px; font-weight: 900; color: #0B192C; }
        .logo span { color: #F0782A; }
        .badge { background: #E8F8EE; color: #34C759; padding: 6px 16px; border-radius: 20px; font-weight: 800; font-size: 13px; }
        .title { text-align: center; margin-bottom: 30px; }
        .title h1 { font-size: 22px; margin-bottom: 6px; }
        .title p { color: #8E8E93; font-size: 13px; }
        .info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; background: #F8F9FA; padding: 20px; border-radius: 12px; margin-bottom: 30px; }
        .info-item { font-size: 13px; }
        .info-item label { color: #8E8E93; display: block; font-size: 11px; font-weight: 700; text-transform: uppercase; margin-bottom: 2px; }
        .info-item value { font-weight: 800; }
        .escrow-box { background: #FFF4EE; border: 1px solid #F0782A; border-radius: 12px; padding: 16px; text-align: center; margin-bottom: 30px; }
        .footer { text-align: center; font-size: 11px; color: #8E8E93; border-top: 1px solid #F2F2F7; padding-top: 20px; }
      </style>
    </head>
    <body>
      <div class="certificate-card">
        <div class="header">
          <div class="logo">MyWorks <span>Protect</span></div>
          <div class="badge">VERIFICADO Y GARANTIZADO</div>
        </div>

        <div class="title">
          <h1>Certificado Digital de Garantía y Trabajo Conforme</h1>
          <p>N° de Certificado: ${data.certificateId} | Fecha: ${data.serviceDate}</p>
        </div>

        <div class="info-grid">
          <div class="info-item">
            <label>Cliente Beneficiario</label>
            <value>${data.clientName}</value>
          </div>
          <div class="info-item">
            <label>Profesional Certificado</label>
            <value>${data.workerName} (${data.profession})</value>
          </div>
          <div class="info-item">
            <label>Monto Total Liberado Escrow</label>
            <value style="color: #34C759;">$${data.totalAmount.toLocaleString('es-CL')} CLP</value>
          </div>
          <div class="info-item">
            <label>PIN de Confirmación</label>
            <value>**** ${data.pinCode.substring(2)} (Verificado)</value>
          </div>
        </div>

        <div class="escrow-box">
          <h3 style="color: #F0782A; margin-bottom: 4px;">Garantía MyWorks de 30 Días Activa</h3>
          <p style="font-size: 12px; margin: 0;">Hash de Transacción Seguro: <code>${data.transactionHash}</code></p>
        </div>

        <div class="footer">
          <p>Este documento constituye el comprobante digital oficial de prestación de servicio y garantía Escrow MyWorks Chile.</p>
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
