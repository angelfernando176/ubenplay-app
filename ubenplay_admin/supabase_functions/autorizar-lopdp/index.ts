// Supabase Edge Function: smart-api (autorizar-lopdp)
// Recibe ?id=<id_usuario>&token=<token_autorizacion> y marca lopdp = 1.
// ⚠️ Supabase NO permite servir HTML (reescribe text/html → text/plain), así que
// devolvemos TEXTO PLANO legible para que el usuario entienda la confirmación.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

function texto(titulo: string, mensaje: string, ok: boolean): string {
  const marca = ok ? '✓' : '!';
  return `${marca} ${titulo}\n\n${mensaje}\n\n— HEPTASOFT`;
}

Deno.serve(async (req) => {
  const url = new URL(req.url);
  const id = url.searchParams.get('id');
  const token = url.searchParams.get('token');
  const encabezados = { 'Content-Type': 'text/plain; charset=utf-8' };

  if (!id || !token) {
    return new Response(
      texto('Enlace inválido', 'El enlace no es válido o está incompleto. Si crees que es un error, contacta a tu profesor.', false),
      { status: 400, headers: encabezados },
    );
  }

  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
    auth: { persistSession: false },
  });

  const { data: usuario, error } = await supabase
    .from('usuarios')
    .select('id_usuario,nombre,apellido')
    .eq('id_usuario', Number(id))
    .eq('token_autorizacion', token)
    .single();

  if (error || !usuario) {
    return new Response(
      texto('Enlace expirado o no válido', 'No pudimos validar tu autorización. Si ya autorizaste antes, no es necesario hacerlo de nuevo.', false),
      { status: 404, headers: encabezados },
    );
  }

  const { error: updErr } = await supabase
    .from('usuarios')
    .update({ lopdp: 1 })
    .eq('id_usuario', Number(id));

  if (updErr) {
    return new Response(
      texto('Algo salió mal', 'No pudimos registrar tu autorización. Inténtalo de nuevo en unos minutos.', false),
      { status: 500, headers: encabezados },
    );
  }

  const nombre = [usuario.nombre, usuario.apellido].filter(Boolean).join(' ');
  return new Response(
    texto(
      '¡Gracias por tu autorización!',
      `Hola ${nombre}, tu autorización para el tratamiento de tus datos personales quedó registrada correctamente.\n\nYa puedes volver a la aplicación HEPTASOFT y seguir practicando alemán.`,
      true,
    ),
    { headers: encabezados },
  );
});
