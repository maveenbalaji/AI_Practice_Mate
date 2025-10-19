import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../models/language.dart';

class SearchableLanguageDropdown extends StatelessWidget {
  final Language? selectedLanguage;
  final List<Language> languages;
  final Function(Language?) onChanged;

  const SearchableLanguageDropdown({
    super.key,
    required this.selectedLanguage,
    required this.languages,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownSearch<Language>(
      items: languages,
      itemAsString: (Language language) => language.name,
      onChanged: onChanged,
      selectedItem: selectedLanguage,
      dropdownDecoratorProps: const DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText: "Programming Language",
          hintText: "Select or search for a language",
        ),
      ),
      popupProps: const PopupProps.menu(
        showSearchBox: true,
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            labelText: "Search Language...",
          ),
        ),
        fit: FlexFit.loose,
      ),
      dropdownBuilder: (context, selectedLanguage) {
        if (selectedLanguage == null) {
          return const Text("Select a language");
        }
        return Row(
          children: [
            Expanded(
              child: Text(
                selectedLanguage.name,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            Text(
              '${selectedLanguage.rating.toStringAsFixed(2)}%',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        );
      },
      filterFn: (language, filter) {
        return language.name.toLowerCase().contains(filter.toLowerCase());
      },
    );
  }
}
