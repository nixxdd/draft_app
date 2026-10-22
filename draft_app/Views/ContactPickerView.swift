//
//  ContactPickerView.swift
//  draft_app
//
//  Created by Stefania Rosciano on 20/10/2026.
//

import SwiftUI
import ContactsUI

struct ContactPickerView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    var onSelectContacts: ([CNContact]) -> Void
    var onCancel: (() -> Void)? = nil

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        picker.displayedPropertyKeys = [
            CNContactGivenNameKey,
            CNContactFamilyNameKey,
            CNContactNicknameKey,
            CNContactImageDataKey,
            CNContactThumbnailImageDataKey,
            CNContactBirthdayKey,
            CNContactPhoneNumbersKey,
            CNContactEmailAddressesKey,
            CNContactJobTitleKey,
            CNContactDepartmentNameKey,
            CNContactOrganizationNameKey
        ]
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, CNContactPickerDelegate {
        let parent: ContactPickerView

        init(_ parent: ContactPickerView) {
            self.parent = parent
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
            parent.onSelectContacts(contacts)
            parent.dismiss()
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            parent.onSelectContacts([contact])
            parent.dismiss()
        }

        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            parent.onCancel?()
            parent.dismiss()
        }
    }
}
