"""Sistema de progreso para operaciones largas"""
import threading
import time

# Almacena el progreso de cada tarea: {task_id: {'total': N, 'current': N, 'status': 'running'|'done'|'error', 'message': ''}}
_progress = {}
_lock = threading.Lock()

def start_task(task_id, total):
    """Iniciar una tarea con N items"""
    with _lock:
        _progress[task_id] = {'total': total, 'current': 0, 'status': 'running', 'message': ''}

def update_progress(task_id, current, message=''):
    """Actualizar progreso de la tarea"""
    with _lock:
        if task_id in _progress:
            _progress[task_id]['current'] = current
            _progress[task_id]['message'] = message

def finish_task(task_id, message='Completado'):
    """Marcar tarea como finalizada"""
    with _lock:
        if task_id in _progress:
            _progress[task_id]['status'] = 'done'
            _progress[task_id]['message'] = message

def fail_task(task_id, error='Error'):
    """Marcar tarea como fallida"""
    with _lock:
        if task_id in _progress:
            _progress[task_id]['status'] = 'error'
            _progress[task_id]['message'] = error

def get_progress(task_id):
    """Obtener progreso actual"""
    with _lock:
        return _progress.get(task_id, {'total': 0, 'current': 0, 'status': 'unknown', 'message': ''})

def cleanup_old_tasks():
    """Limpiar tareas terminadas hace más de 5 minutos"""
    with _lock:
        to_remove = []
        for tid, data in _progress.items():
            if data['status'] in ('done', 'error'):
                to_remove.append(tid)
        for tid in to_remove:
            del _progress[tid]
