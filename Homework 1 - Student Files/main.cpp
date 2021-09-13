#include "Book.hpp"

#include <iostream>
#include <iomanip>
#include <memory>       // unique_ptr
#include <utility>      // move()
#include <vector>

int main(){
    std::cout << std::showpoint << std::fixed << std::setprecision(2)
              << "Add your book into the shopping cart by entering their information.\n"
              << "  Enclose string entries in quotes, and seperate fields with commas.\n"
              << "  Enter CTRL-Z (Windows) or CTRL-D (Linux) to quit\n\n";
    
    // Create an empty collection of smart pointers-to-book items
    std::vector<std::unique_ptr<Book>> shoppingCart;

    // Prompt for, and then for each book input by the user read the ISBN code until end of file
    Book book;
    while(std::cout << "Enter ISBN, Title, Author, and Price\n", std::cin >> book){
        shoppingCart.push_back(std::make_unique<Book>(std::move(book)));
        std::cout << "Item added to shopping cart: " << *shoppingCart.back() << "\n\n";
    }

    // All items are now in the shopping cart, so display them in reverse order
    // Use constat iterators to avoid changin theh contents of the things pointer to, and use reverse iterators to walk backward
    std::cout << "\n\nHere is an itemized list of the items in your shopping cart:\n";
    for(auto i = shoppingCart.crbegin(); i < shoppingCart.crend(); ++i) std::cout<< **i << '\n'; // **i == *shoppingCart[i]

    return 0;
}