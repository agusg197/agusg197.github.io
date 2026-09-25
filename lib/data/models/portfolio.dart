import '../../core/i18n/strings.dart';

/// A string that exists in both locales. JSON accepts either
/// `{"es": "...", "en": "..."}` or a plain string (used for both).
class L10n {
  const L10n(this.es, this.en);

  factory L10n.fromJson(Object? json) {
    if (json is Map) {
      final es = (json['es'] ?? json['en'] ?? '').toString();
      final en = (json['en'] ?? json['es'] ?? '').toString();
      return L10n(es, en);
    }
    final v = (json ?? '').toString();
    return L10n(v, v);
  }

  static const empty = L10n('', '');

  final String es;
  final String en;

  String of(AppLocale l) => l == AppLocale.es ? es : en;
  bool get isEmpty => es.isEmpty && en.isEmpty;

  static List<L10n> listFrom(Object? json) =>
      (json as List? ?? const []).map(L10n.fromJson).toList(growable: false);
}

/// A list of strings per locale: `{"es": [...], "en": [...]}`.
class L10nList {
  const L10nList(this.es, this.en);

  factory L10nList.fromJson(Object? json) {
    if (json is Map) {
      final es = (json['es'] as List? ?? const [])
          .map((e) => e.toString())
          .toList(growable: false);
      final en = (json['en'] as List? ?? const [])
          .map((e) => e.toString())
          .toList(growable: false);
      return L10nList(es, en.isEmpty ? es : en);
    }
    return const L10nList([], []);
  }

  final List<String> es;
  final List<String> en;

  List<String> of(AppLocale l) => l == AppLocale.es ? es : en;
}

Map<String, dynamic> _map(Object? o) =>
    o is Map ? Map<String, dynamic>.from(o) : <String, dynamic>{};

List<Map<String, dynamic>> _maps(Object? o) =>
    (o as List? ?? const []).map(_map).toList(growable: false);

/// El JSON guarda el enlace de correo como `mailto:` a secas. La direccion se
/// arma acá, con las dos mitades, para que el asset no contenga ninguna.
List<SocialLink> _completarCorreo(List<SocialLink> links, String user, String host) {
  if (user.isEmpty || host.isEmpty) return links;
  return [
    for (final l in links)
      l.url == 'mailto:'
          ? SocialLink(label: l.label, url: 'mailto:$user@$host', icon: l.icon)
          : l,
  ];
}

class SocialLink {
  const SocialLink({required this.label, required this.url, required this.icon});

  factory SocialLink.fromJson(Map<String, dynamic> j) => SocialLink(
        label: (j['label'] ?? '').toString(),
        url: (j['url'] ?? '').toString(),
        icon: (j['icon'] ?? 'link').toString(),
      );

  final String label;
  final String url;

  /// Icon key resolved in the UI layer (`github`, `linkedin`, `mail`, `link`).
  final String icon;
}

class StatItem {
  const StatItem({
    required this.value,
    required this.suffix,
    required this.label,
  });

  factory StatItem.fromJson(Map<String, dynamic> j) => StatItem(
        value: (j['value'] as num?)?.toInt() ?? 0,
        suffix: (j['suffix'] ?? '').toString(),
        label: L10n.fromJson(j['label']),
      );

  final int value;
  final String suffix;
  final L10n label;
}

/// Identity shared by every profile.
class Person {
  const Person({
    required this.name,
    required this.handle,
    required this.location,
    required this.status,
    required this.emailUser,
    required this.emailHost,
    required this.languages,
    required this.links,
    required this.photo,
  });

  factory Person.fromJson(Map<String, dynamic> j) => Person(
        name: (j['name'] ?? '').toString(),
        handle: (j['handle'] ?? '').toString(),
        location: L10n.fromJson(j['location']),
        status: L10n.fromJson(j['status']),
        emailUser: (j['emailUser'] ?? '').toString(),
        emailHost: (j['emailHost'] ?? '').toString(),
        languages: L10n.fromJson(j['languages']),
        links: _completarCorreo(
          _maps(j['links']).map(SocialLink.fromJson).toList(growable: false),
          (j['emailUser'] ?? '').toString(),
          (j['emailHost'] ?? '').toString(),
        ),
        photo: (j['photo'] as String?)?.trim(),
      );

  final String name;
  final String handle;
  final L10n location;
  final L10n status;
  /// El correo viaja partido en el JSON y se arma acá: un rastreador que lea
  /// el asset no encuentra ninguna dirección hecha.
  final String emailUser;
  final String emailHost;

  String get email => '$emailUser@$emailHost';
  final L10n languages;
  final List<SocialLink> links;

  /// Retrato para la ranura del carnet. Null deja la ranura vacía.
  final String? photo;
}

class Skill {
  const Skill({required this.name, required this.level});

  factory Skill.fromJson(Map<String, dynamic> j) => Skill(
        name: (j['name'] ?? '').toString(),
        level: ((j['level'] as num?)?.toDouble() ?? 0).clamp(0.0, 1.0),
      );

  final String name;
  final double level;
}

class SkillCategory {
  const SkillCategory({required this.name, required this.items});

  factory SkillCategory.fromJson(Map<String, dynamic> j) => SkillCategory(
        name: L10n.fromJson(j['name']),
        items: _maps(j['items']).map(Skill.fromJson).toList(growable: false),
      );

  final L10n name;
  final List<Skill> items;
}

/// One way of presenting the same person: the Flutter profile or the AI one.
/// Los CV disponibles, uno por idioma.
///
/// Hoy hay solo inglés. Cuando exista el castellano se agrega al JSON y la
/// página lo entrega sola; mientras tanto entrega el que hay y avisa en qué
/// idioma está, que es mejor que una descarga sorpresa.
class CvFiles {
  const CvFiles(this.porIdioma);

  factory CvFiles.fromJson(dynamic j) {
    if (j is String) {
      // Forma vieja: un archivo sin idioma declarado.
      final ruta = j.trim();
      return CvFiles(ruta.isEmpty ? const {} : {'': ruta});
    }
    if (j is Map) {
      return CvFiles({
        for (final e in j.entries)
          e.key.toString(): e.value.toString(),
      }..removeWhere((_, v) => v.isEmpty));
    }
    return const CvFiles({});
  }

  final Map<String, String> porIdioma;

  bool get isEmpty => porIdioma.isEmpty;

  /// El archivo para [locale], o el único que haya.
  String? rutaPara(AppLocale locale) =>
      porIdioma[locale.name] ??
      (porIdioma.isEmpty ? null : porIdioma.values.first);

  /// El idioma del archivo que se entrega para [locale], en mayúsculas
  /// (`EN`), o null si el archivo no lo declara.
  String? idiomaDe(AppLocale locale) {
    if (porIdioma.containsKey(locale.name)) return locale.name.toUpperCase();
    if (porIdioma.isEmpty) return null;
    final idioma = porIdioma.keys.first;
    return idioma.isEmpty ? null : idioma.toUpperCase();
  }

  /// El idioma del archivo que se va a bajar, en mayúsculas, solo cuando **no**
  /// coincide con el de la página. Null quiere decir que no hay nada que
  /// aclarar.
  String? avisoIdioma(AppLocale locale) {
    if (porIdioma.containsKey(locale.name) || porIdioma.isEmpty) return null;
    final idioma = porIdioma.keys.first;
    return idioma.isEmpty ? null : idioma.toUpperCase();
  }
}

class ProfileVariant {
  const ProfileVariant({
    required this.id,
    required this.label,
    required this.headline,
    required this.roles,
    required this.bio,
    required this.cv,
    required this.stats,
    required this.projectOrder,
    required this.skills,
  });

  factory ProfileVariant.fromJson(Map<String, dynamic> j) => ProfileVariant(
        id: (j['id'] ?? '').toString(),
        label: L10n.fromJson(j['label']),
        headline: L10n.fromJson(j['headline']),
        roles: L10nList.fromJson(j['roles']),
        bio: L10n.fromJson(j['bio']),
        cv: CvFiles.fromJson(j['cv']),
        stats: _maps(j['stats']).map(StatItem.fromJson).toList(growable: false),
        projectOrder: (j['projectOrder'] as List? ?? const [])
            .map((e) => e.toString())
            .toList(growable: false),
        skills:
            _maps(j['skills']).map(SkillCategory.fromJson).toList(growable: false),
      );

  final String id;
  final L10n label;
  final L10n headline;
  final L10nList roles;
  final L10n bio;

  /// Asset path of the CV to download for this profile.
  final CvFiles cv;
  final List<StatItem> stats;
  final List<String> projectOrder;
  final List<SkillCategory> skills;
}

class ExperienceEntry {
  const ExperienceEntry({
    required this.company,
    required this.role,
    required this.period,
    required this.summary,
    required this.highlights,
    required this.stack,
    required this.current,
    required this.profiles,
  });

  factory ExperienceEntry.fromJson(Map<String, dynamic> j) => ExperienceEntry(
        company: (j['company'] ?? '').toString(),
        role: L10n.fromJson(j['role']),
        period: L10n.fromJson(j['period']),
        summary: L10n.fromJson(j['summary']),
        highlights: L10n.listFrom(j['highlights']),
        stack: (j['stack'] as List? ?? const [])
            .map((e) => e.toString())
            .toList(growable: false),
        current: j['current'] == true,
        profiles: (j['profiles'] as List? ?? const [])
            .map((e) => e.toString())
            .toList(growable: false),
      );

  final String company;
  final L10n role;
  final L10n period;
  final L10n summary;
  final List<L10n> highlights;
  final List<String> stack;
  final bool current;

  /// Profile ids this entry belongs to. Empty means every profile.
  final List<String> profiles;

  bool showsIn(String profileId) =>
      profiles.isEmpty || profiles.contains(profileId);
}

/// A headline number on a project card.
class ProjectMetric {
  const ProjectMetric({required this.value, required this.label});

  factory ProjectMetric.fromJson(Map<String, dynamic> j) => ProjectMetric(
        value: (j['value'] ?? '').toString(),
        label: L10n.fromJson(j['label']),
      );

  final String value;
  final L10n label;
}

/// One stage of a project's pipeline walkthrough.
class PipelineStage {
  const PipelineStage({
    required this.id,
    required this.title,
    required this.detail,
    required this.risk,
  });

  factory PipelineStage.fromJson(Map<String, dynamic> j) => PipelineStage(
        id: (j['id'] ?? '').toString(),
        title: L10n.fromJson(j['title']),
        detail: L10n.fromJson(j['detail']),
        risk: j['risk'] == null ? null : L10n.fromJson(j['risk']),
      );

  final String id;
  final L10n title;
  final L10n detail;

  /// What can go wrong at this stage, when there is something worth saying.
  final L10n? risk;
}

/// A measured results table, with the finding that came out of it.
class EvalTable {
  const EvalTable({
    required this.title,
    required this.columns,
    required this.rows,
    required this.note,
    required this.finding,
  });

  factory EvalTable.fromJson(Map<String, dynamic> j) => EvalTable(
        title: L10n.fromJson(j['title']),
        columns: (j['columns'] as List? ?? const [])
            .map((e) => e.toString())
            .toList(growable: false),
        rows: (j['rows'] as List? ?? const [])
            .map((r) => (r as List? ?? const [])
                .map((e) => e.toString())
                .toList(growable: false))
            .toList(growable: false),
        note: L10n.fromJson(j['note']),
        finding: L10n.fromJson(j['finding']),
      );

  final L10n title;
  final List<String> columns;
  final List<List<String>> rows;
  final L10n note;
  final L10n finding;

  bool get isEmpty => rows.isEmpty;
}

class GalleryShot {
  const GalleryShot({required this.image, required this.caption});

  factory GalleryShot.fromJson(Map<String, dynamic> j) => GalleryShot(
        image: (j['image'] ?? '').toString(),
        caption: L10n.fromJson(j['caption']),
      );

  final String image;
  final L10n caption;
}

/// Configuration of the playable, API-free simulation for a project.
class ProjectDemo {
  const ProjectDemo({
    required this.kind,
    required this.hint,
    required this.samples,
  });

  factory ProjectDemo.fromJson(Map<String, dynamic> j) => ProjectDemo(
        kind: (j['kind'] ?? '').toString(),
        hint: L10n.fromJson(j['hint']),
        samples: (j['samples'] as List? ?? const [])
            .map((e) => e.toString())
            .toList(growable: false),
      );

  final String kind;
  final L10n hint;
  final List<String> samples;
}

/// Un paso del recorrido contado para alguien que no programa.
class PlainStep {
  const PlainStep({required this.title, required this.text});

  factory PlainStep.fromJson(Map<String, dynamic> j) => PlainStep(
        title: L10n.fromJson(j['title']),
        text: L10n.fromJson(j['text']),
      );

  final L10n title;
  final L10n text;
}

/// El proyecto explicado sin jerga, para el taller de la calle. Los pasos y
/// las métricas van en el mismo orden que `pipeline` y `metrics`.
class ProjectPlain {
  const ProjectPlain({
    required this.what,
    required this.problem,
    required this.analogy,
    required this.steps,
    required this.learned,
    required this.metrics,
  });

  factory ProjectPlain.fromJson(Map<String, dynamic> j) => ProjectPlain(
        what: L10n.fromJson(j['what']),
        problem: L10n.fromJson(j['problem']),
        analogy: L10n.fromJson(j['analogy']),
        steps: _maps(j['steps']).map(PlainStep.fromJson).toList(growable: false),
        learned: L10n.fromJson(j['learned']),
        metrics: L10n.listFrom(j['metrics']),
      );

  final L10n what;
  final L10n problem;
  final L10n analogy;
  final List<PlainStep> steps;
  final L10n learned;
  final List<L10n> metrics;
}

class Project {
  const Project({
    required this.id,
    required this.name,
    required this.tagline,
    required this.description,
    required this.tags,
    required this.year,
    required this.repoUrl,
    required this.demoUrl,
    required this.private,
    required this.featured,
    required this.accent,
    required this.metrics,
    required this.pipeline,
    required this.evals,
    required this.gallery,
    required this.demo,
    this.kind = 'app',
    this.liveUrl,
    this.embeddable = false,
    this.plain,
  });

  factory Project.fromJson(Map<String, dynamic> j) {
    String? url(Object? v) {
      final s = v?.toString().trim();
      return (s == null || s.isEmpty) ? null : s;
    }

    return Project(
      id: (j['id'] ?? '').toString(),
      name: (j['name'] ?? '').toString(),
      tagline: L10n.fromJson(j['tagline']),
      description: L10n.fromJson(j['description']),
      tags: (j['tags'] as List? ?? const [])
          .map((e) => e.toString())
          .toList(growable: false),
      year: (j['year'] ?? '').toString(),
      repoUrl: url(j['repoUrl']),
      demoUrl: url(j['demoUrl']),
      private: j['private'] == true,
      featured: j['featured'] == true,
      accent: (j['accent'] ?? 'cyan').toString(),
      metrics:
          _maps(j['metrics']).map(ProjectMetric.fromJson).toList(growable: false),
      pipeline: _maps(j['pipeline'])
          .map(PipelineStage.fromJson)
          .toList(growable: false),
      evals: j['evals'] == null ? null : EvalTable.fromJson(_map(j['evals'])),
      gallery:
          _maps(j['gallery']).map(GalleryShot.fromJson).toList(growable: false),
      demo: j['demo'] == null ? null : ProjectDemo.fromJson(_map(j['demo'])),
      kind: (j['kind'] ?? 'app').toString(),
      liveUrl: url(j['liveUrl']),
      embeddable: j['embeddable'] == true,
      plain: j['plain'] == null ? null : ProjectPlain.fromJson(_map(j['plain'])),
    );
  }

  final String id;
  final String name;
  final L10n tagline;
  final L10n description;
  final List<String> tags;
  final String year;
  final String? repoUrl;
  final String? demoUrl;
  final bool private;
  final bool featured;

  /// Palette key: `cyan`, `yellow`, `magenta`, `violet`.
  final String accent;
  final List<ProjectMetric> metrics;
  final List<PipelineStage> pipeline;
  final EvalTable? evals;
  final List<GalleryShot> gallery;
  final ProjectDemo? demo;

  /// `app` (móvil o escritorio, va a los talleres) o `web` (va al arcade).
  final String kind;

  /// El sitio publicado. Va en el JSON y no en el código porque los dominios
  /// cambian: el de Bontà Dolce, sin ir más lejos.
  final String? liveUrl;

  /// Si el sitio se deja mostrar dentro de un iframe. Solo se prende después
  /// de mirar las cabeceras reales de la respuesta.
  final bool embeddable;

  /// La explicación simple. Sin ella el taller usa la descripción técnica.
  final ProjectPlain? plain;

  bool get isWeb => kind == 'web';

  bool get hasDetail =>
      pipeline.isNotEmpty ||
      (evals != null && !evals!.isEmpty) ||
      gallery.isNotEmpty ||
      demo != null;
}

class PortfolioData {
  const PortfolioData({
    required this.isMock,
    required this.person,
    required this.profiles,
    required this.experience,
    required this.projects,
  });

  factory PortfolioData.fromJson(Map<String, dynamic> j) => PortfolioData(
        isMock: j['mock'] == true,
        person: Person.fromJson(_map(j['person'])),
        profiles: _maps(j['profiles'])
            .map(ProfileVariant.fromJson)
            .toList(growable: false),
        experience: _maps(j['experience'])
            .map(ExperienceEntry.fromJson)
            .toList(growable: false),
        projects:
            _maps(j['projects']).map(Project.fromJson).toList(growable: false),
      );

  /// True while the page runs on placeholder content.
  final bool isMock;
  final Person person;
  final List<ProfileVariant> profiles;
  final List<ExperienceEntry> experience;
  final List<Project> projects;

  ProfileVariant profileAt(int index) =>
      profiles.isEmpty ? _fallbackProfile : profiles[index % profiles.length];

  Project? projectById(String id) {
    for (final p in projects) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Projects ordered the way [profile] wants them, with anything it did not
  /// list appended so nothing silently disappears.
  List<Project> projectsFor(ProfileVariant profile) {
    final ordered = <Project>[];
    for (final id in profile.projectOrder) {
      final p = projectById(id);
      if (p != null) ordered.add(p);
    }
    for (final p in projects) {
      if (!ordered.contains(p)) ordered.add(p);
    }
    return ordered;
  }

  List<ExperienceEntry> experienceFor(ProfileVariant profile) =>
      experience.where((e) => e.showsIn(profile.id)).toList(growable: false);

  static const _fallbackProfile = ProfileVariant(
    id: 'default',
    label: L10n.empty,
    headline: L10n.empty,
    roles: L10nList([], []),
    bio: L10n.empty,
    cv: CvFiles({}),
    stats: [],
    projectOrder: [],
    skills: [],
  );
}
