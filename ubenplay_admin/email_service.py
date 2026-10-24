"""Envío de correos (SMTP Gmail) — código de activación y autorización LOPDP."""
import os
import secrets
import smtplib
from datetime import datetime
from email.mime.application import MIMEApplication
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import cm
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer

_BASE = os.path.dirname(os.path.abspath(__file__))
SUPABASE_URL = 'https://jtrrqbnxhxxqjcpizjuy.supabase.co'
# Nombre de la Edge Function desplegada en Supabase (se puede cambiar con LOPDP_FUNC)
FUNC_AUTORIZAR = os.environ.get('LOPDP_FUNC', 'smart-api')


def _smtp_config():
    """Lee SMTP_* del .env (solo esas claves; no toca DATABASE_URL)."""
    env = {}
    try:
        with open(os.path.join(_BASE, '.env')) as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    k, v = line.split('=', 1)
                    if k.startswith('SMTP_'):
                        env[k] = v.strip()
    except FileNotFoundError:
        pass
    return {
        'host': env.get('SMTP_HOST', 'smtp.gmail.com'),
        'port': int(env.get('SMTP_PORT', '587')),
        'user': env.get('SMTP_USER', 'a.fernando1468@gmail.com'),
        'password': env.get('SMTP_PASSWORD', '').replace(' ', ''),
        'from': env.get('SMTP_FROM', 'a.fernando1468@gmail.com'),
    }


def generar_token():
    return secrets.token_hex(16)


def link_autorizacion(usuario, token):
    return f'{SUPABASE_URL}/functions/v1/{FUNC_AUTORIZAR}?id={usuario.id_usuario}&token={token}'


def _html_boton_autorizar(link):
    """Botón de autorización compatible con Gmail + URL cruda de respaldo."""
    return (
        f'<table role="presentation" cellspacing="0" cellpadding="0" border="0" '
        f'style="margin:18px 0"><tr><td style="border-radius:8px;background:#58CC02" '
        f'align="center"><a href="{link}" style="display:inline-block;padding:14px 26px;'
        f'color:#ffffff;font-size:16px;font-weight:bold;text-decoration:none">'
        f'AUTORIZAR TRATAMIENTO DE DATOS PERSONALES</a></td></tr></table>'
        f'<p style="font-size:12px;color:#888888;word-break:break-all;margin-top:6px">'
        f'Si el botón no funciona, copia y pega este enlace en tu navegador:<br/>'
        f'<a href="{link}">{link}</a></p>'
    )


# ── PDF de autorización (texto del documento .docx) ──────────────
_PDF_TITULO = 'AUTORIZACIÓN PARA EL TRATAMIENTO DE DATOS PERSONALES'
_PDF_SECCIONES = [
    ('1. Finalidad de este documento',
     'Este documento tiene por objeto informar sobre el tratamiento de datos personales realizado por '
     'CORPORACIÓN PRISMA en relación con el uso de HEPTASOFT y obtener la autorización correspondiente. '
     'La autorización comprende el tratamiento de los datos personales del usuario que realiza el registro '
     'y, cuando corresponda, de los datos del niño, niña o adolescente respecto del cual actúa como representante legal.'),
    ('2. Datos personales tratados',
     'Durante el registro podrán proporcionarse: nombre, apellido, correo electrónico, rango de edad, país; '
     'y en el caso de menores: nombre, apellido, rango de edad y país del niño, niña o adolescente. '
     'Los datos serán tratados únicamente para las finalidades informadas y conforme a la normativa aplicable.'),
    ('3. Finalidades del tratamiento',
     'Funcionamiento de la APP (gestionar el registro, administrar el perfil y permitir el funcionamiento de las '
     'funcionalidades de HEPTASOFT); perfilamiento y personalización; publicidad y comunicaciones; y recordatorios de uso.'),
    ('4. Autorización',
     'Al pulsar el enlace "AUTORIZAR TRATAMIENTO DE DATOS PERSONALES", el titular declara haber leído la información, '
     'tener acceso a la Política de Privacidad, comprender las finalidades y autorizar el tratamiento de los datos '
     'personales para las finalidades indicadas.'),
    ('5. Autorización y finalidades opcionales',
     'En la página de confirmación podrá seleccionar las finalidades opcionales (perfilamiento, publicidad, '
     'recordatorios), que podrán aceptarse o rechazarse de manera independiente.'),
    ('6. Representación legal',
     'Cuando los datos correspondan a un niño, niña o adolescente, la persona que realiza la autorización declara '
     'actuar en calidad de padre, madre o representante legal.'),
    ('7. Retiro de la autorización',
     'La autorización podrá ser retirada mediante los mecanismos habilitados. Correo: a.fernando1468@gmail.com'),
    ('8. Registro de la autorización',
     'Se registrará: identificador de la solicitud, correo electrónico, fecha y hora de envío, de acceso y de '
     'autorización, versión del documento y finalidades autorizadas.'),
    ('9. Confirmación',
     'La autorización se completa mediante la página segura a la que conduce el enlace. La fecha y hora registradas '
     'constituirán parte de la evidencia del proceso de autorización.'),
]


def generar_pdf_autorizacion(usuario):
    """Genera el PDF de autorización LOPDP y devuelve sus bytes."""
    from io import BytesIO
    buf = BytesIO()
    doc = SimpleDocTemplate(buf, pagesize=A4, topMargin=2 * cm, bottomMargin=2 * cm)
    styles = getSampleStyleSheet()
    titulo = ParagraphStyle('titulo', parent=styles['Title'], fontSize=13, leading=18, spaceAfter=12)
    cuerpo = ParagraphStyle('cuerpo', parent=styles['BodyText'], fontSize=9.5, leading=13, spaceAfter=8)

    elementos = [Paragraph(_PDF_TITULO, titulo)]
    elementos.append(Paragraph(
        f'Aplicación: HEPTASOFT<br/>Responsable del tratamiento: Fernando Escobar<br/>'
        f'Correo de contacto: a.fernando1468@gmail.com<br/>Versión: 1.0<br/>'
        f'Fecha: {datetime.now().strftime("%Y/%m/%d")}', cuerpo))
    for t, txt in _PDF_SECCIONES:
        elementos.append(Paragraph(f'<b>{t}</b>', cuerpo))
        elementos.append(Paragraph(txt, cuerpo))
        elementos.append(Spacer(1, 4))
    doc.build(elementos)
    return buf.getvalue()


def _enviar(destinatarios, asunto, html, pdf_bytes=None, pdf_nombre='Autorizacion_Datos_Personales.pdf'):
    cfg = _smtp_config()
    msg = MIMEMultipart('mixed')
    msg['Subject'] = asunto
    msg['From'] = cfg['from']
    msg['To'] = ', '.join(destinatarios)
    msg.attach(MIMEText(html, 'html', 'utf-8'))
    if pdf_bytes:
        adj = MIMEApplication(pdf_bytes, _subtype='pdf')
        adj.add_header('Content-Disposition', 'attachment', filename=pdf_nombre)
        msg.attach(adj)

    with smtplib.SMTP(cfg['host'], cfg['port']) as s:
        s.starttls()
        s.login(cfg['user'], cfg['password'])
        s.sendmail(cfg['from'], destinatarios, msg.as_string())


def enviar_correo_codigo(usuario, codigo, token=None):
    """Correo de activación con el código de 6 dígitos + explicación LOPDP + PDF + link."""
    if token is None:
        token = generar_token()
    usuario.token_autorizacion = token
    link = link_autorizacion(usuario, token)
    pdf = generar_pdf_autorizacion(usuario)
    es_menor = usuario.rango_edad == 1

    nombre = usuario.nombre or ''
    cuerpo = (
        f'<p>Hola <b>{nombre}</b>,</p>'
        f'<p>Gracias por registrarte en <b>HEPTASOFT</b>. Este correo es para activar tu acceso.</p>'
        f'<p>Tu <b>código de activación</b> es:</p>'
        f'<p style="font-size:28px;letter-spacing:6px;font-weight:bold;color:#58CC02">{codigo}</p>'
        f'<p>Además, necesitamos que autorices el uso de tus datos personales (LOPDP). '
        f'Revisa el documento adjunto (PDF).</p>'
    )
    if es_menor:
        cuerpo += (
            f'<p>Este correo se envía también a tu representante legal, quien deberá autorizar '
            f'el tratamiento de tus datos personales.</p>'
        )
    else:
        cuerpo += _html_boton_autorizar(link)

    # Destinatarios: menor → usuario + representante (representante con link, menor sin link)
    if es_menor and usuario.correo_representante:
        # Correo al representante (CON link)
        html_rep = cuerpo + _html_boton_autorizar(link)
        _enviar([usuario.correo_representante], 'Autorización LOPDP — HEPTASOFT', html_rep, pdf)
        # Correo al menor (SIN link)
        _enviar([usuario.correo], 'Tu código de activación — HEPTASOFT', cuerpo, pdf)
    else:
        _enviar([usuario.correo], 'Tu código de activación — HEPTASOFT', cuerpo, pdf)


def enviar_correo_autorizacion(usuario, token=None):
    """Reenvío de la autorización LOPDP (sin código)."""
    if token is None:
        token = generar_token()
    usuario.token_autorizacion = token
    link = link_autorizacion(usuario, token)
    pdf = generar_pdf_autorizacion(usuario)
    es_menor = usuario.rango_edad == 1
    nombre = usuario.nombre or ''

    base = (
        f'<p>Hola <b>{nombre}</b>,</p>'
        f'<p>Te recordamos que aún no has autorizado el uso de tus datos personales (LOPDP). '
        f'Es fácil: revisa el documento adjunto (PDF) y pulsa el enlace de autorización.</p>'
    )
    html_con_link = base + _html_boton_autorizar(link)

    if es_menor and usuario.correo_representante:
        _enviar([usuario.correo_representante], 'Autorización LOPDP — HEPTASOFT', html_con_link, pdf)
        _enviar([usuario.correo], 'Autorización LOPDP — HEPTASOFT', base, pdf)
    else:
        _enviar([usuario.correo], 'Autorización LOPDP — HEPTASOFT', html_con_link, pdf)
