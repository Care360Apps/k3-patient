import '../model/health_tip_model.dart';

/// Bundled editorial essentials remain available without a connection.
/// Sources reviewed 9 November 2026; these are general education, not advice
/// personalised to a diagnosis, medicine or individual clinical history.
final care360HealthEssentials = <Data>[
  Data(id: -1, title: 'Build a varied plate',
    blogRef: 'WHO — Healthy diet',
    desc: '<p>Choose a variety of foods across the week, including vegetables, '
      'fruit, beans, wholegrains and suitable protein sources.</p>'
      '<ol><li>Add vegetables or fruit to a meal.</li>'
      '<li>Try beans or a wholegrain food as part of a balanced meal.</li>'
      '<li>Choose water instead of a sugary drink when suitable.</li></ol>'
      '<p>Your needs may differ with a health condition or pregnancy. '
      'Ask your clinician about changes suited to you.</p>'),
  Data(id: -2, title: 'Make hand cleaning a daily habit',
    blogRef: 'WHO — Hand hygiene in community settings',
    desc: '<p>Hand cleaning helps reduce the spread of infections.</p>'
      '<ol><li>Keep soap and clean water accessible.</li>'
      '<li>Clean hands before preparing or eating food and after using '
      'the toilet.</li><li>Clean hands after coughing, sneezing or handling '
      'waste. Help children learn the routine.</li></ol>'),
];

const care360HealthSources = <int, String>{
  -1: 'https://www.who.int/news-room/fact-sheets/detail/healthy-diet',
  -2: 'https://www.who.int/publications/i/item/9789240116559',
};
