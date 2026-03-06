class AppLang {
  static bool isSpanish = false;

  static void setLanguage(bool toSpanish) {
    isSpanish = toSpanish;
  }

  static String get pomodoroTab => isSpanish ? 'POMODORO' : 'POMODORO';
  static String get clockTab => isSpanish ? 'RELOJ' : 'CLOCK';
  static String get focusPhase => isSpanish ? 'ENFOQUE' : 'FOCUS';
  static String get breakPhase => isSpanish ? 'DESCANSO' : 'BREAK';
  static String get shortcutsTitle => isSpanish
      ? 'ATAJOS (Manten pulsado para borrar)'
      : 'DEVICE APPS (Long press to remove)';
  static String get homeButton => isSpanish ? 'Inicio' : 'Home';
  static String get settingsTitle =>
      isSpanish ? 'Ajustes del Pomodoro' : 'Pomodoro Settings';
  static String get focusDuration =>
      isSpanish ? 'Duración de Enfoque' : 'Focus Duration';
  static String get breakDuration =>
      isSpanish ? 'Duración de Descanso' : 'Break Duration';
  static String get saveSettings =>
      isSpanish ? 'Guardar Ajustes' : 'Save Settings';
  static String get min => isSpanish ? 'min' : 'min';
  static String get cancel => isSpanish ? 'Cancelar' : 'Cancel';
  static String get delete => isSpanish ? 'Borrar' : 'Delete';
  static String get add => isSpanish ? 'Agregar' : 'Add';
  static String get languageSetting =>
      isSpanish ? 'Idioma (Language)' : 'Language (Idioma)';
  static String get currentLanguageName => isSpanish ? 'Español' : 'English';
  static String get addActivityHint =>
      isSpanish ? 'Añadir una actividad...' : 'Add an activity...';
  static String get tasksHeader => isSpanish ? 'TAREAS' : 'TASKS';
  static String get pendingSuffix => isSpanish ? 'pendientes' : 'pending';
  static String get noActivities => isSpanish
      ? 'Aún no hay actividades. ¡Estás al día!'
      : 'No activities yet. You\'re all caught up!';
  static String get selectNativeApp =>
      isSpanish ? 'Seleccionar App Nativa' : 'Select Native App';
  static String get selectSound =>
      isSpanish ? 'Seleccionar Sonido' : 'Select Sound';
  static String get currentSound =>
      isSpanish ? 'Sonido Actual' : 'Current Sound';
  static String get defaultSound => isSpanish ? 'Predeterminado' : 'Default';
  static String get customSound => isSpanish ? 'Personalizado' : 'Custom';
}
