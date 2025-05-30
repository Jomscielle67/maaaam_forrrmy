import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class SearchInput extends StatelessWidget {
  const SearchInput({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final TextEditingController searchController = TextEditingController();

    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: TextField(
          controller: searchController,
          textInputAction: TextInputAction.search,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.pushNamed(
                context,
                '/search',
                arguments: value.trim(),
              );
            }
          },
          decoration: InputDecoration(
            fillColor: Colors.white,
            filled: true,
            hintText: 'Search For Products',
            border: OutlineInputBorder(
              borderSide: BorderSide.none,
            ),
      
            prefixIcon: Padding(
              padding: const EdgeInsets.all(14.0),
              child: SvgPicture.asset(
                'assets/icons/search.svg',
                width: 10,
                ),
            ),
          ),
        ),
      ),
    );
  }
}
